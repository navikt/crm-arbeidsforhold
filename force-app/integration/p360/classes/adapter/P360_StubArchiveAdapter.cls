/**
 * Stub implementation of the P360 archive adapter.
 * Used for local development and early orchestration testing before real P360 calls exist.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 Adapter
 */
public with sharing class P360_StubArchiveAdapter implements P360_IArchiveAdapter {
    /**
     * Returns a controlled successful stub response without performing a callout.
     *
     * @param request P360 archive request DTO.
     * @return Controlled stub archive response.
     */
    public P360_ArchiveResponseDto archive(P360_ArchiveRequestDto request) {
        P360_ArchiveResponseDto response = new P360_ArchiveResponseDto();
        response.success = true;
        response.message = 'Stub archive response. No callout was performed.';
        response.externalCaseId = request != null ? request.externalId : null;
        return response;
    }
}
