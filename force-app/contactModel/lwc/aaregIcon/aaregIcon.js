import { LightningElement, api } from 'lwc';
import { ICONS } from './icons';

export default class AaregIcon extends LightningElement {
    @api name;
    @api title;

    get paths() {
        return (ICONS[this.name] ?? []).map((path, index) => ({
            key: `${this.name}-${index}`,
            d: path.d,
            rule: path.evenodd ? 'evenodd' : undefined
        }));
    }

    get ariaHidden() {
        return this.title ? undefined : 'true';
    }

    get svgRole() {
        return this.title ? 'img' : undefined;
    }
}
