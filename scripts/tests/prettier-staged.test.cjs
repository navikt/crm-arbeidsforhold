const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');

let fixtureNumber = 0;
function fixture(t) {
    const directory = path.resolve(__dirname, `.prettier-staged-fixture-${process.pid}-${fixtureNumber++}`);
    fs.mkdirSync(directory, { recursive: true });
    t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const script = path.resolve(__dirname, '../prettier-staged.cjs');
    const run = (...args) => spawnSync(process.execPath, [script, ...args], { cwd: directory, encoding: 'utf8' });
    const write = (file, content) => {
        const target = path.join(directory, file);
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.writeFileSync(target, content);
        return target;
    };
    return { directory, run, write };
}

test('succeeds when there are no staged file arguments', (t) => {
    const f = fixture(t);
    assert.equal(f.run().status, 0);
});

test('formats a filename containing spaces as one argument', (t) => {
    const f = fixture(t);
    const file = f.write('source file.js', 'const value={answer:42};');
    const result = f.run('source file.js');
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.readFileSync(file, 'utf8'), 'const value = { answer: 42 };\n');
});

test('reports missing files and returns a failure status', (t) => {
    const f = fixture(t);
    const result = f.run('missing.js');
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Prettier failed for missing\.js/);
});

test('propagates formatter failures as a non-zero exit status', (t) => {
    const f = fixture(t);
    f.write('invalid.js', 'const = ;');
    const result = f.run('invalid.js');
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Prettier failed for invalid\.js/);
});

test('check mode reports unformatted content and does not modify it', (t) => {
    const f = fixture(t);
    const original = 'const value={answer:42};';
    const file = f.write('check.js', original);
    const result = f.run('--check', 'check.js');
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Would format check\.js/);
    assert.equal(fs.readFileSync(file, 'utf8'), original);
});
