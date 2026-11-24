import { createTestWireAdapter } from '@salesforce/wire-service-jest-util';

export const CurrentPageReference = createTestWireAdapter(jest.fn());

const navigateCalls = [];

export const NavigationMixin = (Base) =>
    class extends Base {
        [NavigationMixin.Navigate](pageReference) {
            navigateCalls.push(pageReference);
        }
    };

NavigationMixin.Navigate = Symbol('Navigate');

export const getNavigateCalls = () => navigateCalls;
export const resetNavigateCalls = () => {
    navigateCalls.length = 0;
};
