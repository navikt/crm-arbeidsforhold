/**
 * Internal DTO for the core SIF CaseDocumentResult contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_CaseDocumentResultDto {
    /** Document record number. */
    public String recno;

    /** Document number assigned by 360. */
    public String documentNumber;

    /** Document title. */
    public String documentTitle;

    /** eArchive imported document number when applicable. */
    public String importedDocumentNumber;

    /** Files connected to the document. */
    public List<P360_CaseDocumentFileResultDto> files;
}
