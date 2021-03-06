#' @name updateObject
#' @author Michael Steinbaugh
#' @inherit AcidGenerics::updateObject
#' @note Updated 2021-04-02.
#'
#' @details
#' Update old objects created by the bcbioRNASeq package. The session
#' information metadata is preserved from the time when the bcbio data was
#' originally loaded into R.
#'
#' @section Legacy `bcbioRNADataSet` class:
#'
#' Support for `bcbioRNADataSet` objects was dropped in v0.2.0 of the package.
#' If you need to load one of these objects, please install an older release.
#'
#' @section Legacy `bcbioRnaseq` package:
#'
#' The previous `bcbioRnaseq` package (note case) must be reinstalled to load
#' objects from versions <= 0.0.20. We changed the name of the package to
#' `bcbioRNASeq` starting in v0.0.21.
#'
#' @inheritParams AcidRoxygen::params
#' @param rowRanges `GRanges` or `NULL`.
#'   Row annotations. Since we converted to `RangedSummarizedExperiment` in
#'   v0.2.0, this option had to be added to enable updating of newly required
#'   `rowRanges` slot. Objects that are >= v0.2 don't require this argument and
#'   it can be left `NULL`.
#'
#' @examples
#' data(bcb)
#' updateObject(bcb)
#'
#' ## Example that depends on remote file.
#' ## > x <- import(file.path(bcbioRNASeqTestsURL, "bcbioRNASeq_0.1.4.rds"))
#' ## > x <- updateObject(x)
#' ## > x
NULL



## Updated 2021-04-02.
`updateObject,bcbioRNASeq` <-  # nolint
    function(
        object,
        rowRanges = NULL,
        ...,
        verbose = FALSE
    ) {
        assert(isFlag(verbose))
        metadata <- metadata(object)
        ## Renamed 'version' to 'packageVersion' on 2021-03-16.
        version <- metadata[["packageVersion"]]
        if (is.null(version)) {
            version <- metadata[["version"]]
        }
        assert(is(version, c("package_version", "numeric_version")))
        if (isTRUE(verbose)) {
            h1("Update object")
            alert(sprintf(
                fmt = paste(
                    "Updating {.var bcbioRNASeq} object from version {.val %s}",
                    "to {.val %s}."
                ),
                as.character(version),
                as.character(.pkgVersion)
            ))
        }
        ## Legacy slots --------------------------------------------------------
        if (isTRUE(verbose)) {
            h2("Legacy slots")
        }
        ## NAMES
        if (!is.null(slot(object, "NAMES"))) {
            if (isTRUE(verbose)) {
                alertInfo("{.var NAMES} slot must be set to {.val NULL}.")
            }
            slot(object, "NAMES") <- NULL
        }
        ## elementMetadata
        if (ncol(slot(object, "elementMetadata")) != 0L) {
            if (isTRUE(verbose)) {
                alertInfo(paste(
                    "{.var elementMetadata} slot must contain a",
                    "zero-column {.var DataFrame}."
                ))
            }
            slot(object, "elementMetadata") <-
                as(matrix(nrow = nrow(object), ncol = 0L), "DataFrame")
        }
        ## rowRanges
        if (!.hasSlot(object, "rowRanges")) {
            if (is.null(rowRanges)) {
                if (isTRUE(verbose)) {
                    alertWarning("Slotting empty {.fun rowRanges}.")
                }
                assays <- slot(object, "assays")
                ## Extract assay matrix from ShallowSimpleListAssays object.
                if (packageVersion("SummarizedExperiment") >= "1.15") {
                    ## Bioconductor 3.10+.
                    assay <- getListElement(x = assays, i = 1L)
                } else {
                    ## Legacy method.
                    assay <- assays[[1L]]
                }
                rownames <- rownames(assay)
                assert(isCharacter(rownames))
                rowRanges <- emptyRanges(names = rownames)
                rowData <- slot(object, "elementMetadata")
                mcols(rowRanges) <- rowData
            }
            assert(isAny(rowRanges, c("GRanges", "GRangesList")))
            slot(object, "rowRanges") <- rowRanges
        } else if (
            .hasSlot(object, "rowRanges") &&
            !is.null(rowRanges)
        ) {
            stop(
                "Object already contains 'rowRanges()'.\n",
                "Don't attempt to slot new ones with 'rowRanges' argument."
            )
        }
        ## Check for legacy bcbio slot.
        if (.hasSlot(object, "bcbio")) {
            if (isTRUE(verbose)) {
                alertWarning("Dropping legacy {.var bcbio} slot.")
            }
        }
        ## Metadata ------------------------------------------------------------
        if (isTRUE(verbose)) {
            h2("Metadata")
        }
        ## bcbioLog
        if (is.null(metadata[["bcbioLog"]])) {
            if (isTRUE(verbose)) {
                alertWarning("Setting {.var bcbioLog} as empty character.")
            }
            metadata[["bcbioLog"]] <- character()
        }
        ## bcbioCommandsLog
        if (is.null(metadata[["bcbioCommandsLog"]])) {
            if (isTRUE(verbose)) {
                alertWarning(
                    "Setting {.var bcbioCommands} as empty character."
                )
            }
            metadata[["bcbioCommandsLog"]] <- character()
        }
        ## call
        if (!"call" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alertWarning("Stashing empty {.var call}.")
            }
            metadata[["call"]] <- call(name = "bcbioRNASeq")
        }
        ## caller
        if (!"caller" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alertWarning("Setting {.var caller} as salmon.")
            }
            metadata[["caller"]] <- "salmon"
        }
        ## dataVersions
        dataVersions <- metadata[["dataVersions"]]
        if (is(dataVersions, "data.frame")) {
            metadata[["dataVersions"]] <- as(dataVersions, "DataFrame")
        }
        ## design
        if ("design" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alertWarning("Dropping legacy {.var design}.")
            }
            metadata[["design"]] <- NULL
        }
        ## ensemblRelease
        if ("ensemblVersion" %in% names(metadata)) {
            ## Renamed in v0.2.0.
            if (isTRUE(verbose)) {
                alert(
                    "Renaming {.var ensemblVersion} to {.var ensemblRelease}."
                )
            }
            names(metadata)[
                names(metadata) == "ensemblVersion"] <- "ensemblRelease"
        }
        if (!is.integer(metadata[["ensemblRelease"]])) {
            if (isTRUE(verbose)) {
                alert("Setting {.var ensemblRelease} as integer.")
            }
            metadata[["ensemblRelease"]] <-
                as.integer(metadata[["ensemblRelease"]])
        }
        ## genomeBuild
        if (!is.character(metadata[["genomeBuild"]])) {
            if (isTRUE(verbose)) {
                alertWarning(
                    "Setting {.var genomeBuild} as empty character."
                )
            }
            metadata[["genomeBuild"]] <- character()
        }
        ## gffFile
        if ("gtfFile" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alert("Renaming {.var gtfFile} to {.var gffFile}.")
            }
            names(metadata)[
                names(metadata) == "gtfFile"] <- "gffFile"
        }
        if (!"gffFile" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alert("Setting {.var gffFile} as empty character.")
            }
            metadata[["gffFile"]] <- character()
        }
        ## gtf
        if ("gtf" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alertWarning("Dropping stashed GTF in {.var gtf}.")
            }
            metadata[["gtf"]] <- NULL
        }
        ## lanes
        if (!is.integer(metadata[["lanes"]])) {
            if (isTRUE(verbose)) {
                alert("Setting {.var lanes} as integer.")
            }
            metadata[["lanes"]] <- as.integer(metadata[["lanes"]])
        }
        ## level
        if (!"level" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alert("Setting {.var level} as genes.")
            }
            metadata[["level"]] <- "genes"
        }
        ## packageVersion
        metadata[["previousVersion"]] <- metadata[["version"]]
        metadata[["packageVersion"]] <- .pkgVersion
        metadata[["version"]] <- NULL
        ## programVersions
        if (!"programVersions" %in% names(metadata) &&
            "programs" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alert("Renaming {.var programs} to {.var programVersions}.")
            }
            names(metadata)[
                names(metadata) == "programs"] <- "programVersions"
        }
        programVersions <- metadata[["programVersions"]]
        if (is(programVersions, "data.frame")) {
            if (isTRUE(verbose)) {
                alert(
                    "Coercing {.var programVersions} to {.var DataFrame}."
                )
            }
            metadata[["programVersions"]] <- as(programVersions, "DataFrame")
        }
        ## sampleMetadataFile
        if (!is.character(metadata[["sampleMetadataFile"]])) {
            if (isTRUE(verbose)) {
                alert(
                    "Setting {.var sampleMetadataFile} as empty character."
                )
            }
            metadata[["sampleMetadataFile"]] <- character()
        }
        ## sessionInfo
        ## Support for legacy devtoolsSessionInfo stash.
        ## Previously, we stashed both devtools* and utils* variants.
        if ("devtoolsSessionInfo" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alert("Simplifying stashed {.var sessionInfo}.")
            }
            names(metadata)[
                names(metadata) == "devtoolsSessionInfo"] <- "sessionInfo"
            metadata[["utilsSessionInfo"]] <- NULL
        }
        ## template
        if ("template" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alert("Dropping legacy {.var template}.")
            }
            metadata[["template"]] <- NULL
        }
        ## Dead genes: "missing" or "unannotated".
        if ("missingGenes" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alertWarning("Dropping {.var missingGenes} from metadata.")
            }
            metadata[["missingGenes"]] <- NULL
        }
        if ("unannotatedGenes" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alertWarning(
                    "Dropping {.var unannotatedGenes} from metadata."
                )
            }
            metadata[["unannotatedGenes"]] <- NULL
        }
        ## yamlFile
        if ("yamlFile" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alert("Dropping {.var yamlFile} file path.")
            }
            metadata[["yamlFile"]] <- NULL
        }
        ## tximport-specific
        if (isSubset(metadata[["caller"]], .tximportCallers)) {
            if (isTRUE(verbose)) {
                h3("tximport")
            }
            ## countsFromAbundance
            if (!"countsFromAbundance" %in% names(metadata)) {
                countsFromAbundance <- "lengthScaledTPM"
                if (isTRUE(verbose)) {
                    alertWarning(sprintf(
                        "Setting {.var countsFromAbundance} as {.val %s}.",
                        countsFromAbundance
                    ))
                }
                metadata[["countsFromAbundance"]] <- countsFromAbundance
            }
            ## tx2gene
            tx2gene <- metadata[["tx2gene"]]
            if (!is(tx2gene, "Tx2Gene")) {
                if (isTRUE(verbose)) {
                    alert(
                        "Coercing {.var tx2gene} to {.var Tx2Gene} class."
                    )
                }
                assert(is.data.frame(tx2gene))
                tx2gene <- as(tx2gene, "DataFrame")
                colnames(tx2gene) <- c("txId", "geneId")
                rownames(tx2gene) <- NULL
                metadata[["tx2gene"]] <- Tx2Gene(tx2gene)
            }
        }
        ## Filter NULL metadata.
        metadata <- Filter(f = Negate(is.null), x = metadata)
        ## Assays --------------------------------------------------------------
        if (isTRUE(verbose)) {
            h2("Assays")
        }
        assays <- assays(object)
        ## These variables are needed for assay handling.
        caller <- metadata[["caller"]]
        assert(
            isString(caller),
            isSubset(caller, .callers)
        )
        level <- metadata[["level"]]
        assert(
            isString(level),
            isSubset(level, .levels)
        )
        ## Ensure raw counts are always named "counts".
        if ("raw" %in% names(assays)) {
            if (isTRUE(verbose)) {
                alert("Renaming {.var raw} assay to {.var counts}.")
            }
            names(assays)[names(assays) == "raw"] <- "counts"
        }
        ## Rename average transcript length matrix.
        if ("length" %in% names(assays)) {
            if (isTRUE(verbose)) {
                alert("Renaming {.var length} assay to {.var avgTxLength}.")
            }
            names(assays)[names(assays) == "length"] <- "avgTxLength"
        }
        ## Drop legacy TMM counts.
        if ("tmm" %in% names(assays)) {
            if (isTRUE(verbose)) {
                alert(paste(
                    "Dropping {.var tmm} from {.fun assays}.",
                    "Calculating on the fly instead."
                ))
            }
            assays[["tmm"]] <- NULL
        }
        ## Gene-level-specific assays (DESeq2). Handle legacy objects where size
        ## factor normalized counts aren't stashed as a matrix. Note that these
        ## will always be length scaled.
        if (level == "genes") {
            ## DESeq2 normalized counts.
            if (is(assays[["normalized"]], "DESeqDataSet")) {
                if (isTRUE(verbose)) {
                    alert(paste(
                        "Coercing {.var normalized} assay from",
                        "{.var DESeqDataSet} to {.var matrix}."
                    ))
                }
                dds <- assays[["normalized"]]
                assays[["normalized"]] <- counts(dds, normalized = TRUE)
            }
            ## Variance-stabilizing transformation.
            if (is(assays[["vst"]], "DESeqTransform")) {
                if (isTRUE(verbose)) {
                    alert(paste(
                        "Coercing {.var vst} assay from {.var DESeqTransform}",
                        "to {.var matrix}."
                    ))
                }
                assays[["vst"]] <- assay(assays[["vst"]])
            }
            ## Regularized log.
            if (is(assays[["rlog"]], "DESeqTransform")) {
                if (isTRUE(verbose)) {
                    alert(paste(
                        "Coercing {.var rlog} assay from {.var DESeqTransform}",
                        "to {.var matrix}."
                    ))
                }
                assays[["rlog"]] <- assay(assays[["rlog"]])
            }
        }
        ## Always put the required assays first.
        assert(isSubset(.assays, names(assays)))
        assays <- assays[unique(c(.assays, names(assays)))]
        ## Check for required caller-specific assays.
        if (caller %in% .tximportCallers) {
            assert(isSubset(.tximportAssays, names(assays)))
        } else if (caller %in% .featureCountsCallers) {
            assert(isSubset(.featureCountsAssays, names(assays)))
        }
        ## Filter NULL assays.
        assays <- Filter(f = Negate(is.null), x = assays)
        ## Row ranges ----------------------------------------------------------
        if (isTRUE(verbose)) {
            h2("Row ranges")
        }
        rowRanges <- rowRanges(object)
        if (hasLength(colnames(mcols(rowRanges)))) {
            colnames(mcols(rowRanges)) <-
                camelCase(colnames(mcols(rowRanges)), strict = TRUE)
            if (any(grepl(
                pattern = "^transcript",
                x = colnames(mcols(rowRanges))
            ))) {
                colnames(mcols(rowRanges)) <- gsub(
                    pattern = "^transcript",
                    replacement = "tx",
                    x = colnames(mcols(rowRanges))
                )
            }
        }
        ## rowRangesMetadata
        if ("rowRangesMetadata" %in% names(metadata)) {
            if (isTRUE(verbose)) {
                alert(paste(
                    "Moving {.var rowRangesMetadata} into {.var rowRanges}",
                    "metadata."
                ))
            }
            metadata(rowRanges)[["ensembldb"]] <-
                metadata[["rowRangesMetadata"]]
            metadata[["rowRangesMetadata"]] <- NULL
        }
        ## biotype
        if ("biotype" %in% colnames(mcols(rowRanges))) {
            if (isTRUE(verbose)) {
                alert("Renaming {.var biotype} to {.var geneBiotype}.")
            }
            mcols(rowRanges)[["geneBiotype"]] <-
                as.factor(mcols(rowRanges)[["biotype"]])
            mcols(rowRanges)[["biotype"]] <- NULL
        }
        ## broadClass
        if (
            "broadClass" %in% colnames(mcols(rowRanges)) &&
            is.character(mcols(rowRanges)[["broadClass"]])
        ) {
            if (isTRUE(verbose)) {
                alert("Setting {.var broadClass} to factor.")
            }
            mcols(rowRanges)[["broadClass"]] <-
                as.factor(mcols(rowRanges)[["broadClass"]])
        }
        ## ensgene
        if ("ensgene" %in% colnames(mcols(rowRanges))) {
            if (isTRUE(verbose)) {
                alert("Renaming {.var ensgene} to {.var geneId}.")
            }
            mcols(rowRanges)[["geneId"]] <-
                as.character(mcols(rowRanges)[["ensgene"]])
            mcols(rowRanges)[["ensgene"]] <- NULL
        }
        ## symbol
        if ("symbol" %in% colnames(mcols(rowRanges))) {
            if (isTRUE(verbose)) {
                alert("Renaming {.var symbol} to {.var geneName}.")
            }
            mcols(rowRanges)[["geneName"]] <-
                as.factor(mcols(rowRanges)[["symbol"]])
            mcols(rowRanges)[["symbol"]] <- NULL
        }
        ## Use run-length encoding (Rle) for metadata columns.
        ## Recommended method as of v0.3.0 update.
        rowRanges <- encode(rowRanges)
        ## Column data ---------------------------------------------------------
        if (isTRUE(verbose)) {
            h2("Column data")
        }
        colData <- colData(object)
        colnames(colData) <- camelCase(colnames(colData), strict = TRUE)
        ## Move metrics from metadata into colData, if necessary.
        metrics <- metadata[["metrics"]]
        if (!is.null(metrics)) {
            if (isTRUE(verbose)) {
                alert(paste(
                    "Moving {.var metrics} from {.fun metadata} into",
                    "{.fun colData}."
                ))
            }
            assert(is.data.frame(metrics))
            ## Always remove legacy name column.
            metrics[["name"]] <- NULL
            ## Rename 5'3' bias.
            if ("x53Bias" %in% colnames(metrics)) {
                if (isTRUE(verbose)) {
                    alert("Renaming {.var x53Bias} to {.var x5x3Bias}.")
                }
                metrics[["x5x3Bias"]] <- metrics[["x53Bias"]]
                metrics[["x53Bias"]] <- NULL
            }
            ## Rename rRNA rate.
            if (!"rrnaRate" %in% colnames(metrics)) {
                col <- grep(
                    pattern = "rrnarate",
                    x = colnames(metrics),
                    ignore.case = TRUE,
                    value = TRUE
                )
                assert(isString(col))
                if (isTRUE(verbose)) {
                    alert(sprintf(
                        "Renaming {.var %s} to {.var rrnaRate}.", col
                    ))
                }
                metrics[["rrnaRate"]] <- metrics[[col]]
                metrics[[col]] <- NULL
            }
            ## Only include columns not already present in colData.
            setdiff <- setdiff(colnames(metrics), colnames(colData))
            metrics <- metrics[, sort(setdiff), drop = FALSE]
            colData <- cbind(colData, metrics)
            metadata[["metrics"]] <- NULL
        }
        ## Remove legacy sample identifier and description columns, if present.
        colData[["description"]] <- NULL
        colData[["sampleID"]] <- NULL
        colData[["sampleId"]] <- NULL
        ## Return --------------------------------------------------------------
        se <- SummarizedExperiment(
            assays = assays,
            rowRanges = rowRanges,
            colData = colData,
            metadata = metadata
        )
        bcb <- new(Class = "bcbioRNASeq", se)
        validObject(bcb)
        if (isTRUE(verbose)) {
            alertSuccess(sprintf(
                "Update of {.var %s} object was successful.",
                "bcbioRNASeq"
            ))
        }
        bcb
    }



#' @rdname updateObject
#' @export
setMethod(
    f = "updateObject",
    signature = signature("bcbioRNASeq"),
    definition = `updateObject,bcbioRNASeq`
)
