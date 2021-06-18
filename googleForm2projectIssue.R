#! /usr/bin/R

# clean environment
rm(list=ls())
#-------------------------------------------------------------------------------
# convenient functions
usePackage <- function(p) {
  if (!is.element(p, installed.packages()[,1]))
    install.packages(p, dep = TRUE)
  require(p, character.only = TRUE)
}

# format row to markdown file content
row2md<-function(data,row_number){
  # subset to row for issue
  d1<-data[row_number,] %>% select(-Timestamp,-project_issue)
  
  # get headers and clean
  headers <- colnames(d1) %>% gsub("\\."," ",.) %>% gsub(" $","",.) %>% paste(.,":",sep="") %>% paste("**",.,"**",sep="")
  
  # get cols that are not empty
  w<-which(apply(d1[row_number,],2,function(x) x=="")==TRUE %>% sum())
  if (length(w)>0){
    d1<-d1[,-w]
    headers<-headers[-w]
  }

  # for each column concatenate the header and the content
  z<-lapply(1:NCOL(d1), function(x) {paste(headers[x],d1[,x],sep="\n")}) 
  md<-do.call("paste",args=c(z,sep="\n\n"))
  
  # output text in markdown format
  return(md)
  
}
#-------------------------------------------------------------------------------
usePackage("dplyr")
#-------------------------------------------------------------------------------
args<-commandArgs( trailingOnly = TRUE)
input_file<-args[1]
out_file<-gsub(".csv","_issues.csv",input_file)
# create directory to output issues in md format
if (!dir.exists("project_issues")){dir.create("project_issues")}
#-------------------------------------------------------------------------------
# read issues, downloaded from the google form
d<-read.csv(input_file)

# assign issue number, format it to contain 3 characters
ns<-1:NROW(d)
n1 <- which(nchar(ns)==1)
ns[n1]<-gsub("^","00",ns[n1])
n2 <- which(nchar(ns)==2)
ns[n2]<-gsub("^","0",ns[n2])
rm(n1,n2)

d$project_issue <- paste("BHD2021",ns,d$Timestamp,sep="_") %>% gsub("\\/",".",.) %>% strsplit(.," ") %>% sapply("[[",1) # not sure what is the best format but...

# flag new issues
old_issues<-list.files("project_issues/",pattern="md") %>% gsub(".md","",.)
d <- d %>% mutate(project_new=if_else(project_issue %in% old_issues,0,1))

# save  in md format, if project file does not already exist
for (r in 1:NROW(d)){
  fname<-paste0("project_issues/",d$project_issue[r],".md")
  if (!file.exists(fname)){
    sink(fname)
    row2md(data=d,row_number=r) %>% cat()
    sink()
  }
  rm(fname)
}
rm(r)


# save edited projects csv, including project_issue tag
write.csv(d,file=out_file,row.names=FALSE,quote=TRUE)

# save list of new projects for which an issue need to be opened:
new<-d %>% filter(project_new==1) %>% select(project_issue,Project.title.) 
write.table(new,paste0("project_issues/list_new_projects.txt"),row.names=FALSE,col.names=FALSE,quote=TRUE)
