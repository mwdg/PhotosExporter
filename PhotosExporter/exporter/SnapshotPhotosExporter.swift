//
//  SnapshotPhotosExporter.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 21.03.18.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation

/**
 * simple export mode which creates one snapshot folder, with hard links to the original files to save disk space (only if the target directory is in the same file system as the Photos Library)
 */
class SnapshotPhotosExporter : PhotosExporter {
    
    private var subTargetPath: String {
        return "\(targetPath)/Snapshot"
    }
    
    public var deleteFlatPath = true
    
    override func exportFoldersFlat(photosMetadata: PhotosMetadata) throws {
        
        if exportOriginals {
            logger.info("export originals photos to \(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath) folder")

            var candidatesToLinkTo: [FlatFolderDescriptor] = []

            if let baseExportPath = baseExportPath {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(baseExportPath)/\(originalsRelativePath)/\(flatRelativePath)")
            }

            try exportFolderFlat(
                photosMetadata: photosMetadata,
                flatPath: "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)",
                candidatesToLinkTo: candidatesToLinkTo,
                version: PhotoVersion.originals)
            
        }
        if exportCurrent {
            logger.info("export current photos to \(inProgressPath)/\(currentRelativePath)/\(flatRelativePath) folder")

            var candidatesToLinkTo: [FlatFolderDescriptor] = []

            if let baseExportPath = baseExportPath {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(baseExportPath)/\(currentRelativePath)/\(flatRelativePath)")
            }

            if exportOriginals {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)")
            }

            try exportFolderFlat(
                photosMetadata: photosMetadata,
                flatPath: "\(inProgressPath)/\(currentRelativePath)/\(flatRelativePath)",
                candidatesToLinkTo: candidatesToLinkTo,
                version: PhotoVersion.current)
        }
        if exportDerived {
            logger.info("export derived photos to \(inProgressPath)/\(derivedRelativePath)/\(flatRelativePath) folder")

            var candidatesToLinkTo: [FlatFolderDescriptor] = []

            if let baseExportPath = baseExportPath {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(baseExportPath)/\(derivedRelativePath)/\(flatRelativePath)")
            }

            if exportOriginals {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)")
            }

            try exportFolderFlat(
                photosMetadata: photosMetadata,
                flatPath: "\(inProgressPath)/\(derivedRelativePath)/\(flatRelativePath)",
                candidatesToLinkTo: candidatesToLinkTo,
                version: PhotoVersion.derived)
        }
    }

    let stopWatchLinkFile = StopWatch("fileManager.linkItem", LogLevel.info, addFileSizes: false)

    override func copyOrLinkFileInPhotosLibrary(sourceUrl: URL, targetUrl: URL) throws {
        if try filesAreOnSameDevice(path1: sourceUrl.path, path2: targetUrl.deletingLastPathComponent().path) {
            logger.debug("link image: \(sourceUrl) to \(targetUrl.lastPathComponent)")
            do {
                stopWatchLinkFile.start()
                try fileManager.linkItem(at: sourceUrl, to: targetUrl)
                stopWatchLinkFile.stop()
                statistics.countLinkedFiles += 1
            }
            catch let error as NSError {
                logger.error("\(String(describing: index)): Unable to link file: \(error)")
                throw error
            }
        } else {
            // copy
            try super.copyOrLinkFileInPhotosLibrary(sourceUrl: sourceUrl, targetUrl: targetUrl)
        }
    }
    
    private func filesAreOnSameDevice(path1: String, path2: String) throws -> Bool {
        let attributes1 = try fileManager.attributesOfItem(atPath: path1)
        let attributes2 = try fileManager.attributesOfItem(atPath: path2)
        let deviceIdentifier1 = attributes1[FileAttributeKey.systemNumber]
        let deviceIdentifier2 = attributes2[FileAttributeKey.systemNumber]
        if deviceIdentifier1 != nil && deviceIdentifier2 != nil {
            if (deviceIdentifier1 as! NSNumber) == (deviceIdentifier2 as! NSNumber) {
                return true
            }
        }
        return false
    }
    
    /**
     * Finish the filesystem structures; invariant:
     * if no folder "InProgress" but folders with date exist, and there is a symbolic link "Latest", there was no error.
     */
    override func finishExport() throws {
        try super.finishExport()
        
        // remove the ".flat" folders
        if (deleteFlatPath) {
            try deleteFolderIfExists(atPath: "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)")
            try deleteFolderIfExists(atPath: "\(inProgressPath)/\(currentRelativePath)/\(flatRelativePath)")
        }
        
        // remove the "Current" folder
        try deleteFolderIfExists(atPath: subTargetPath)
        
        // rename "InProgress" folder to "Current"
        do {
            try fileManager.moveItem(atPath: inProgressPath, toPath: subTargetPath)
        } catch {
            logger.error("Error renaming InProgress folder: \(error) => abort export")
            throw error
        }
    }
    
    func deleteFolderIfExists(atPath path: String) throws {
        do {
            if fileManager.fileExists(atPath: path) {
                logger.info("Delete folder: \(path)")
                for (retryCounter, _) in [0...2].enumerated() {
                    do {
                        try fileManager.removeItem(atPath: path)
                    } catch {
                        if retryCounter == 2 {
                            throw error
                        }
                    }
                }
            }
        } catch {
            logger.error("Error deleting folder \(path)")
            throw error
        }
    }
}
