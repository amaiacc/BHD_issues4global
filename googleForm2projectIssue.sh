#! /bin/bash

# script to download google form and format it into a md file that can be submitted as a git issue
# Amaia Carrión-Castillo, 2021.06.18, edited 2022.11.07

## specify the url for the target google form as argument
url_file=$1
year=$2
url_file=https://docs.google.com/spreadsheets/d/1CTYnf0aFwSdK2Ph2x-S9tITyOr3BeG9k5QtbMG91NXQ/export?format=csv
year=2022

# define directories
bhd_dir=/home/ina/Escritorio/amaia/BHD/

# clone git project where issues should be submited
#--------------------------------------------------------
## clone amaia's BHD repo for testing purposes
# git clone https://github.com/amaiacc/BHD_issues4global
#--------------------------------------------------------
# clone global brainhack repo
# cd ${bhd_dir}
# git clone https://github.com/brainhackorg/global${year}.git
# cd ${bhd_dir}/global${year}
#--------------------------------------------------------
# Read projects from google form, and format them into individual md files --> to be submitted as issues
cd ${bhd_dir}
mkdir -p project_data project_issues

# define target format, from git an example git issue --> in templates
## https://github.com/brainhackorg/global2020/issues/new?assignees=&labels=project&template=project-submission-template.md&title=

# get google form as csv output
wget --no-check-certificate ${url_file} -O project_data/BHD${year}_projects.csv

# replace all LF that are not preceded by CR with a space (i.e. keep CRLF)
## from: https://stackoverflow.com/questions/50737164/how-to-use-sed-to-substitute-lf-with-space-but-not-crlf
awk 'BEGIN{RS=ORS="\r\n"}/\n/{sub(/\n/,"")}1' project_data/BHD${year}_projects.csv > project_data/BHD${year}_projects_edited.csv
awk '!/\r$/{printf "%s",$0;next}1' project_data/BHD${year}_projects.csv > project_data/BHD${year}_projects_edited.csv
# add \n at the end of the file, if not present
## from: https://unix.stackexchange.com/questions/31947/how-to-add-a-newline-to-the-end-of-a-file
## and replace BrainHackDonostia for BrainhackGlobal in header
sed -i -e '$a\' project_data/BHD${year}_projects_edited.csv | sed 's/Goals for Brainhack Donostia 2022/Goals for Brainhack Global/g'

# make sure it's in unix format, otherwise problems when reading with R if there are newline and other system specific characters
dos2unix ./project_data/BHD${year}_projects_edited.csv

# run this script to create an adequatelly formatted markdown file for each project
Rscript --verbose ${bhd_dir}/BHD_issues4global/googleForm2projectIssue.R ./project_data/BHD${year}_projects_edited.csv

#--------------------------------------------------------
# define target repo, to get issues from:
target_repo=BHD_issues4global
target_repo=global${year}

# get issues in target repo
cd ${bhd_dir}/${target_repo} # cd to global repo if issues should be submitted there.. just trying it here first

# get list of current issues in repo
gh issue list | grep "^[^#;]" | awk -F"\t" '{print $3}'> open_issues_BH${year}.txt # create list open issue titles --> do not resubmit if project has an open issue

# For each new project, open a new issue in github
# condition on having a list_new_projects.txt file
if [ -f ${bhd_dir}/project_issues/list_new_projects.csv ]
 then 
 while IFS="," read -r v1 v2 remainder
  do
   id=$(echo $v1 | sed 's/"//g')
   title=$(echo $v2 | sed 's/"//g' | awk -F":" '{print $1}' )
   # only open issue if not listed as an open issue
   if ! grep -q "${title}" open_issues_BH${year}.txt
    then
     echo "The title for ${id} is ${title}."
    gh issue create --title "${title}" --body-file ${bhd_dir}/project_issues/${id}.md
    else
     echo "Issue for project with title '"${title}"' is already open."
   fi
 done < ${bhd_dir}/project_issues/list_new_projects.csv
 # remove list of new projects after creating the issues - to avoid resubmitting them
 #rm ${bhd_dir}/BHD_issues4global/project_issues/list_new_projects.csv # remove file 
fi

