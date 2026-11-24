import { LightningElement, api } from 'lwc';

const VARIANTS = {
    info: { icon: 'InformationSquareFill', title: 'Informasjon' },
    warning: { icon: 'ExclamationmarkTriangleFill', title: 'Advarsel' },
    error: { icon: 'XMarkOctagonFill', title: 'Feil' },
    success: { icon: 'CheckmarkCircleFill', title: 'Suksess' }
};

export default class AaregAlert extends LightningElement {
    @api variant = 'info';
    @api size;

    get config() {
        return VARIANTS[this.variant] ?? VARIANTS.info;
    }

    get alertClass() {
        const size = this.size === 'small' ? ' navds-alert--small' : '';
        return `navds-alert navds-alert--${VARIANTS[this.variant] ? this.variant : 'info'}${size}`;
    }

    get iconName() {
        return this.config.icon;
    }

    get iconTitle() {
        return this.config.title;
    }
}
