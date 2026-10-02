/**
 * Starts the executable CLI by adapting process arguments and streams to the embeddable application.
 * Importing this module runs the command and assigns its result to the process exit code.
 */
import { runCli } from './cli-app.js';

const exitCode = await runCli(process.argv.slice(2), {
    stdout: (line) => process.stdout.write(`${line}\n`),
    stderr: (line) => process.stderr.write(`${line}\n`),
    isTTY: process.stdout.isTTY
});

process.exitCode = exitCode;
