import Foundation

public extension Process {
	struct ReturnValue {
		public let stdout: String
		public let stderr: String
		public let exitCode: ExitCode

		// swiftlint:disable:next nesting
		public enum ExitCode {
			case success
			case failure(Int32)

			init(_ code: Int32) {
				self = switch code {
				case 0: .success
				default: .failure(code)
				}
			}
		}
	}

	static func run(
		_ command: String,
		arguments: [String],
		environment: [String: String] = ProcessInfo.processInfo.environment,
		workingDirectory: URL? = nil,
		joinPipes: Bool = false
	) async throws -> ReturnValue {
		try await withCheckedThrowingContinuation { continuation in
			DispatchQueue.global(qos: .userInitiated).async {
				let stdout = Pipe()
				let stderr = joinPipes ? stdout : Pipe()

				let process = Process()
				let executable: String
				let args: [String]

				if command.starts(with: ".") || command.starts(with: "/") {
					executable = command.replacingOccurrences(of: "\\", with: "")
					args = arguments
				} else {
					executable = "/usr/bin/env"
					args = [command] + arguments
				}

				process.executableURL = URL(fileURLWithPath: executable)
				process.arguments = args.map { $0.replacingOccurrences(of: "\\", with: "") }
				process.standardOutput = stdout
				process.standardError = stderr
				process.environment = environment

				if let workingDirectory {
					process.currentDirectoryURL = workingDirectory
				}

				do {
					try process.run()
				} catch {
					continuation.resume(throwing: error)
				}

				let stdoutData: Data
				let stderrData: Data
				let stdoutHandle = stdout.fileHandleForReading
				let stderrHandle = stderr.fileHandleForReading

				if stdoutHandle.fileDescriptor != stderrHandle.fileDescriptor {
					stderrData = stderrHandle.readDataToEndOfFile()
				} else {
					stderrData = Data()
				}

				stdoutData = stdoutHandle.readDataToEndOfFile()
				process.waitUntilExit()

				try? stdoutHandle.close()
				try? stderrHandle.close()

				continuation.resume(returning: .init(
					stdout: String(decoding: stdoutData, as: UTF8.self),
					stderr: String(decoding: stderrData, as: UTF8.self),
					exitCode: .init(process.terminationStatus)
					)
				)
			}
		}
	}
}
