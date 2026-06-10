import LightningModal from 'lightning/modal';

/**
 * First-step login modal for aareg_home.
 *
 * The user must choose "Virksomhet" or "Meg selv" before proceeding.
 *  – "Neste" → closes the modal and returns the chosen value to the caller
 *
 * Opened programmatically from aareg_home via:
 *   const choice = await AaregRepresentModal.open({ label: '...', size: 'small' });
 */
export default class AaregRepresentModal extends LightningModal {
    /** Currently selected radio value; defaults to 'virksomhet' to match the pre-checked radio. */
    selectedChoice = 'virksomhet';

    /** Disables the Neste button until a choice is made. */
    get isNesteDisabled() {
        return !this.selectedChoice;
    }

    /** Keeps the two radio inputs mutually exclusive via shared name attribute. */
    handleRadioChange(event) {
        this.selectedChoice = event.target.value;
    }

    /**
     * Closes the modal and returns the selected choice to the awaiting caller.
     * The Neste button is disabled when no choice has been made, so selectedChoice
     * is guaranteed to be truthy here.
     */
    handleNeste() {
        if (!this.selectedChoice) return;
        this.close(this.selectedChoice);
    }
}