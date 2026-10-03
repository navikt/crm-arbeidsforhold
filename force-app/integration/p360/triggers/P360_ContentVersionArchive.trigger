trigger P360_ContentVersionArchive on ContentVersion(after insert) {
    P360_ContentVersionArchiveHandler.afterInsert(Trigger.new);
}
