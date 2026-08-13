export class ShowToastEvent extends CustomEvent {
    constructor(detail) {
        super('lightning__showtoast', { detail });
    }
}
