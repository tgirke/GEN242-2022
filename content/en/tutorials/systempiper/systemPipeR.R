## pre code {

## white-space: pre !important;

## overflow-x: scroll !important;

## word-break: keep-all !important;

## word-wrap: initial !important;

## }


## ----setup_dir, echo=FALSE, include=FALSE, message=FALSE, warning=FALSE---------------------------------------------------------------------------------------------------------------------------------------------------
unlink("rnaseq", recursive = TRUE)
systemPipeRdata::genWorkenvir(workflow = "rnaseq")
knitr::opts_knit$set(root.dir = 'rnaseq')


## ----style, echo = FALSE, results = 'asis'--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
BiocStyle::markdown()
options(width=80, max.print=1000)
knitr::opts_chunk$set(
    eval=as.logical(Sys.getenv("KNITR_EVAL", "TRUE")),
    cache=as.logical(Sys.getenv("KNITR_CACHE", "TRUE")), 
    tidy.opts=list(width.cutoff=80), tidy=TRUE)


## ----setup, echo=FALSE, message=FALSE, warning=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------
suppressPackageStartupMessages({
    library(systemPipeR)
    library(BiocParallel)
    library(Biostrings)
    library(Rsamtools)
    library(GenomicRanges)
    library(ggplot2)
    library(GenomicAlignments)
    library(ShortRead)
    library(ape)
    library(batchtools)
    library(magrittr)
})


## ----install, eval=FALSE--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## if (!requireNamespace("BiocManager", quietly=TRUE)) install.packages("BiocManager")
## BiocManager::install("systemPipeR")
## BiocManager::install("systemPipeRdata")


## ----documentation, eval=FALSE--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## library("systemPipeR") # Loads the package
## library(help="systemPipeR") # Lists package info
## vignette("systemPipeR") # Opens vignette


## ----generate_workenvir, eval=FALSE---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sytemPipeRdata::genWorkenvir(workflow="rnaseq")
## setwd("rnaseq")


## ----targetsSE, eval=TRUE, message=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library(systemPipeR)
targetspath <- system.file("extdata", "targets.txt", package = "systemPipeR") 
showDF(read.delim(targetspath, comment.char = "#"))


## ----targetsPE, eval=TRUE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
targetspath <- system.file("extdata", "targetsPE.txt", package = "systemPipeR")
showDF(read.delim(targetspath, comment.char = "#"))


## ----comment_lines, echo=TRUE---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
readLines(targetspath)[1:4]


## ----targetscomp, eval=TRUE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
readComp(file = targetspath, format = "vector", delim = "-")


## ----SPRproject1, eval=TRUE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sal <- SPRproject() 


## ----projectInfo, eval=TRUE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sal
projectInfo(sal)


## ----length, eval=TRUE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
length(sal)


## ----hisat2_mapping, eval=TRUE--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
appendStep(sal) <- SYSargsList(
    step_name = "hisat2_mapping",
    dir = TRUE, 
    targets = "targetsPE.txt", 
    wf_file = "workflow-hisat2/workflow_hisat2-pe.cwl",
    input_file = "workflow-hisat2/workflow_hisat2-pe.yml",
    dir_path = "param/cwl",
    inputvars = c(FileName1 = "_FASTQ_PATH1_", 
                  FileName2 = "_FASTQ_PATH2_", 
                  SampleName = "_SampleName_")
)


## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sal


## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
cmdlist(sal, step = "hisat2_mapping", targets = 1)


## ----output_WF, eval=TRUE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
outfiles(sal)


## ----align_stats, eval=TRUE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
appendStep(sal) <- LineWise(
    code = {
        fqpaths <- getColumn(sal, step = "hisat2_mapping", "targetsWF", column = "FileName1")
        bampaths <- getColumn(sal, step = "hisat2_mapping", "outfiles", column = "samtools_sort_bam")
        read_statsDF <- alignStats(args = bampaths, fqpaths = fqpaths, pairEnd = TRUE)
        write.table(read_statsDF, "results/alignStats.xls", row.names=FALSE, quote=FALSE, sep="\t")
        }, 
    step_name = "align_stats", 
    dependency = "hisat2_mapping")


## ----codeLine, eval=TRUE--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
codeLine(sal, "align_stats")


## ----getColumn, eval=TRUE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
getColumn(sal, step = "hisat2_mapping", "outfiles", column = "samtools_sort_bam")


## ----cleaning, eval=TRUE, include=FALSE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if (file.exists(".SPRproject")) unlink(".SPRproject", recursive = TRUE)
## NOTE: Removing previous project create in the quick starts section


## ----importWF_rmd, eval=TRUE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sal <- SPRproject() 
sal <- importWF(sal, file_path = "systemPipeRNAseq.Rmd")


## ----importWF_details, eval=FALSE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## stepsWF(sal)
## dependency(sal)
## codeLine(sal)
## targetsWF(sal)


## ----table_tools, echo=FALSE, message=T-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library(magrittr)
SPR_software <- system.file("extdata", "SPR_software.csv", package="systemPipeR")
software <- read.delim(SPR_software, sep=",", comment.char = "#")
colors <- colorRampPalette((c("darkseagreen", "indianred1")))(length(unique(software$Category)))
id <- as.numeric(c((unique(software$Category))))
software %>%
  dplyr::mutate(Step = kableExtra::cell_spec(Step, color = "white", bold = TRUE,
    background = factor(Category, id, colors))) %>%
   dplyr::select(Tool, Description, Step) %>%
  dplyr::arrange(Tool) %>%
  kableExtra::kable(escape = FALSE, align = "c", col.names = c("Tool Name",	"Description", "Step")) %>%
  kableExtra::kable_styling(c("striped", "hover", "condensed"), full_width = TRUE) %>%
  kableExtra::scroll_box(width = "100%", height = "500px")


## ----test_tool_path, eval=FALSE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## tryCL(command="grep")


## ----test_software, eval=FALSE--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## tryCL(command = "hisat2") ## "All set up, proceed!"


## ----runWF, eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- runWF(sal)


## ----runWF_error, eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- runWF(sal, steps = c(1,3))


## ----runWF_force, eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- runWF(sal, force = TRUE, warning.stop = FALSE, error.stop = FALSE)


## ----runWF_cluster, eval=FALSE--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## resources <- list(conffile=".batchtools.conf.R",
##                   template="batchtools.slurm.tmpl",
##                   Njobs=18,
##                   walltime=120, ## minutes
##                   ntasks=1,
##                   ncpus=4,
##                   memory=1024, ## Mb
##                   partition = "short"
##                   )
## sal <- addResources(sal, c("hisat2_mapping"), resources = resources)
## sal <- runWF(sal)


## ---- eval=TRUE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
plotWF(sal)


## ---- eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- renderLogs(sal)


## ---- eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- renderReport(sal)


## ----genRna_workflow_single, eval=FALSE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## library(systemPipeRdata)
## genWorkenvir(workflow="rnaseq")
## setwd("rnaseq")


## ----project_rnaseq, eval=FALSE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- SPRproject()
## sal <- importWF(sal, file_path = "systemPipeRNAseq.Rmd", verbose = FALSE)


## ----run_rnaseq, eval=FALSE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- runWF(sal)


## ----plot_rnaseq, eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## plotWF(sal)


## ----report_rnaseq, eval=FALSE--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- renderReport(sal)
## sal <- renderLogs(sal)


## ----genChip_workflow_single, eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## library(systemPipeRdata)
## genWorkenvir(workflow="chipseq")
## setwd("chipseq")


## ----project_chipseq, eval=FALSE------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- SPRproject()
## sal <- importWF(sal, file_path = "systemPipeChIPseq.Rmd", verbose = FALSE)


## ----run_chipseq, eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- runWF(sal)


## ----plot_chipseq, eval=FALSE---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## plotWF(sal)


## ----report_chipseq, eval=FALSE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- renderReport(sal)
## sal <- renderLogs(sal)


## ----genVar_workflow_single, eval=FALSE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## library(systemPipeRdata)
## genWorkenvir(workflow="varseq")
## setwd("varseq")


## ----project_varseq, eval=FALSE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- SPRproject()
## sal <- importWF(sal, file_path = "systemPipeVARseq.Rmd", verbose = FALSE)


## ----run_varseq, eval=FALSE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- runWF(sal)


## ----plot_varseq, eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## plotWF(sal)


## ----report_varseq, eval=FALSE--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- renderReport(sal)
## sal <- renderLogs(sal)


## ----genRibo_workflow_single, eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## library(systemPipeRdata)
## genWorkenvir(workflow="riboseq")
## setwd("riboseq")


## ----project_riboseq, eval=FALSE------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- SPRproject()
## sal <- importWF(sal, file_path = "systemPipeRIBOseq.Rmd", verbose = FALSE)


## ----run_riboseq, eval=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- runWF(sal)


## ----plot_riboseq, eval=FALSE---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## plotWF(sal, rstudio = TRUE)


## ----report_riboseq, eval=FALSE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## sal <- renderReport(sal)
## sal <- renderLogs(sal)
## 

## ----quiting, eval=TRUE, echo=FALSE---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
knitr::opts_knit$set(root.dir = '../')
unlink("rnaseq", recursive = TRUE)


## ----sessionInfo----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sessionInfo()

