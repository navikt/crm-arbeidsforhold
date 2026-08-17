export const NavigationMixin = (Base) =>
    class extends Base {
        [NavigationMixin.Navigate]() {}
    };

NavigationMixin.Navigate = Symbol('Navigate');
