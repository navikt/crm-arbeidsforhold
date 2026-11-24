import { LightningElement, api } from 'lwc';

export const SELF = 'SELF';
const MAX_VISIBLE = 50;

const digits = (value) => (value ?? '').replace(/\s/g, '');
const formatNumber = (value) => digits(value).replace(/^(\d{3})(\d{3})(\d{3})$/, '$1 $2 $3');

let instance = 0;

export default class AaregOrgSelector extends LightningElement {
    @api label = 'Kven gjeld det?';
    @api hint = 'Søk på namn eller organisasjonsnummer. Du må velje sjølv; ingenting er valt på førehand.';
    @api includeSelf = false;
    @api selfLabel = 'Meg selv';
    @api selected;

    _organizations = [];
    query = '';
    open = false;
    activeIndex = -1;
    uid = `org-selector-${++instance}`;

    @api
    get organizations() {
        return this._organizations;
    }
    set organizations(value) {
        this._organizations = Array.isArray(value) ? value : [];
    }

    get inputId() {
        return `${this.uid}-input`;
    }

    get listboxId() {
        return `${this.uid}-listbox`;
    }

    get hintId() {
        return `${this.uid}-hint`;
    }

    get statusId() {
        return `${this.uid}-status`;
    }

    get describedBy() {
        return `${this.hintId} ${this.statusId}`;
    }

    get allOptions() {
        const options = this._organizations.map((organization) => ({
            value: organization.organizationNumber,
            name: organization.name,
            number: formatNumber(organization.organizationNumber),
            parentName: organization.parentName,
            isSelf: false
        }));
        if (this.includeSelf) {
            options.unshift({ value: SELF, name: this.selfLabel, number: '', isSelf: true });
        }
        return options;
    }

    get filtered() {
        const text = this.query.trim().toLowerCase();
        const number = digits(text);
        const matches = this.allOptions.filter(
            (option) =>
                !text ||
                option.isSelf ||
                (option.name ?? '').toLowerCase().includes(text) ||
                (number.length > 0 && /^\d+$/.test(number) && digits(option.value).startsWith(number))
        );
        return matches.slice(0, MAX_VISIBLE).map((option, index) => ({
            ...option,
            id: `${this.uid}-option-${index}`,
            selected: option.value === this.selected,
            className: `option${index === this.activeIndex ? ' option_active' : ''}${option.isSelf ? ' option_self' : ''}`,
            hasParent: Boolean(option.parentName)
        }));
    }

    get organizationMatches() {
        return this.filtered.filter((option) => !option.isSelf).length;
    }

    get statusText() {
        if (!this.open) {
            return '';
        }
        const count = this.organizationMatches;
        return count === 0 ? 'Ingen organisasjonar passar søket.' : `${count} organisasjonar passar søket.`;
    }

    get hasNoMatches() {
        return this.open && this.organizationMatches === 0 && this.query.trim().length > 0;
    }

    get activeDescendant() {
        const option = this.filtered[this.activeIndex];
        return option ? option.id : null;
    }

    get expanded() {
        return this.open ? 'true' : 'false';
    }

    get selectedOption() {
        return this.allOptions.find((option) => option.value === this.selected);
    }

    get selectedText() {
        const option = this.selectedOption;
        if (!option) {
            return 'Ingen valt';
        }
        return option.isSelf ? option.name : `${option.name} (${option.number})`;
    }

    handleFocus() {
        this.open = true;
    }

    handleInput(event) {
        this.query = event.target.value;
        this.open = true;
        this.activeIndex = this.filtered.length > 0 ? 0 : -1;
    }

    handleKeyDown(event) {
        const count = this.filtered.length;
        if (event.key === 'ArrowDown') {
            event.preventDefault();
            this.open = true;
            this.activeIndex = count === 0 ? -1 : (this.activeIndex + 1) % count;
        } else if (event.key === 'ArrowUp') {
            event.preventDefault();
            this.open = true;
            this.activeIndex = count === 0 ? -1 : (this.activeIndex - 1 + count) % count;
        } else if (event.key === 'Enter') {
            if (this.open && this.activeIndex >= 0) {
                event.preventDefault();
                this.choose(this.filtered[this.activeIndex]);
            }
        } else if (event.key === 'Escape') {
            this.open = false;
            this.activeIndex = -1;
        }
    }

    handleOptionMouseDown(event) {
        // Keeps focus in the input so the choice is not lost to blur.
        event.preventDefault();
    }

    handleOptionClick(event) {
        const option = this.filtered.find((candidate) => candidate.value === event.currentTarget.dataset.value);
        this.choose(option);
    }

    handleBlur() {
        this.open = false;
        this.activeIndex = -1;
    }

    choose(option) {
        if (!option) {
            return;
        }
        this.selected = option.value;
        this.query = '';
        this.open = false;
        this.activeIndex = -1;
        this.dispatchEvent(
            new CustomEvent('select', {
                detail: {
                    organizationNumber: option.isSelf ? null : option.value,
                    name: option.name,
                    isSelf: option.isSelf
                }
            })
        );
    }
}
