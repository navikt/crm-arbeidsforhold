const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];
setupFilesAfterEnv.push('<rootDir>/jest-sa11y-setup.js');
module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        '^@salesforce/apex$': '<rootDir>/force-app/tests/jest-mocks/apex',
        '^@salesforce/community/basePath$': '<rootDir>/force-app/tests/jest-mocks/community/basePath',
        '^@salesforce/schema$': '<rootDir>/force-app/tests/jest-mocks/schema',
        '^lightning/navigation$': '<rootDir>/force-app/tests/jest-mocks/lightning/navigation',
        '^lightning/platformShowToastEvent$': '<rootDir>/force-app/tests/jest-mocks/lightning/platformShowToastEvent',
        '^lightning/uiRecordApi$': '<rootDir>/force-app/tests/jest-mocks/lightning/uiRecordApi',
        '^lightning/messageService$': '<rootDir>/force-app/tests/jest-mocks/lightning/messageService'
    },
    setupFiles: ['jest-canvas-mock'],
    setupFilesAfterEnv,
    testTimeout: 10000
};
