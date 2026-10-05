const fs = require('node:fs/promises');
const path = require('node:path');
const prettier = require('prettier');

function withoutFinalNewline(content) {
    return content.replace(/(?:\r\n|\r|\n)$/, '');
}

async function formatFile(filePath, checkOnly) {
    const absolutePath = path.resolve(filePath);
    const info = await prettier.getFileInfo(absolutePath, {
        ignorePath: ['.gitignore', '.prettierignore']
    });

    if (info.ignored || !info.inferredParser) {
        return;
    }

    const source = await fs.readFile(absolutePath, 'utf8');
    const config = await prettier.resolveConfig(absolutePath);
    const formatted = await prettier.format(source, {
        ...config,
        filepath: absolutePath
    });

    if (formatted === source) {
        return;
    }

    if (withoutFinalNewline(formatted) === withoutFinalNewline(source)) {
        process.stdout.write(`Preserving ${filePath}: only the final newline differs.\n`);
        return;
    }

    if (checkOnly) {
        process.stderr.write(`Would format ${filePath}.\n`);
        return false;
    }

    await fs.writeFile(absolutePath, formatted, 'utf8');
    return true;
}

async function main() {
    const args = process.argv.slice(2);
    const checkOnly = args.includes('--check');
    const files = args.filter((argument) => argument !== '--check');
    const failures = [];

    for (const file of files) {
        try {
            const changed = await formatFile(file, checkOnly);
            if (checkOnly && changed === false) {
                failures.push({ file, error: new Error('Prettier changes content beyond the final newline.') });
            }
        } catch (error) {
            failures.push({ file, error });
        }
    }

    for (const failure of failures) {
        process.stderr.write(`Prettier failed for ${failure.file}: ${failure.error.message}\n`);
    }

    if (failures.length > 0) {
        process.exitCode = 1;
    }
}

main();
