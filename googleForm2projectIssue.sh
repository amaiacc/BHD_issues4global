#! /bin/bash

# script to download google form and format it into a md file that can be submitted as a git issue
# Amaia Carrión-Castillo, 2021.06.18

## specify the url for the target google form as argument
url_file=$1

# define directories
mkdir -p project_data project_issues

# define target format, from git an example git issue --> in templates
## https://github.com/brainhackorg/global2020/issues/new?assignees=&labels=project&template=project-submission-template.md&title=


# get google form as csv output

wget --no-check-certificate ${url_file} -O 'project_data/BHD2021_projects.csv' 

# replace all LF that are not preceded by CR with a space (i.e. keep CRLF)
## from: https://stackoverflow.com/questions/50737164/how-to-use-sed-to-substitute-lf-with-space-but-not-crlf
awk 'BEGIN{RS=ORS="\r\n"}/\n/{sub(/\n/,"")}1' 'project_data/BHD2021_projects.csv' > 'project_data/BHD2021_projects_edited.csv'
awk '!/\r$/{printf "%s",$0;next}1' 'project_data/BHD2021_projects.csv' > 'project_data/BHD2021_projects_edited.csv'
# add \n at the end of the file, if not present
## from: https://unix.stackexchange.com/questions/31947/how-to-add-a-newline-to-the-end-of-a-file
sed -i -e '$a\' 'project_data/BHD2021_projects_edited.csv'

# make sure it's in unix format, otherwise problems when reading with R if there are newline and other system specific characters
dos2unix ./project_data/BHD2021_projects_edited.csv

# run this script to create an adequatelly formatted markdown file for each project
Rscript --verbose googleForm2projectIssue.R ./project_data/BHD2021_projects_edited.csv

# For each new project, open a new issue in github (BHD2021?)
gh issue list | grep "^[^#;]" | awk '{print $3}'> open_issues.txt # create list open issue titles --> do not resubmit if project has an open issue

cd project_issues

# condition on having a list_new_projects.txt file
if [ -f list_new_projects.txt ]
then 
 while IFS=" " read -r v1 v2 remainder
  do
   id=$(echo $v1 | sed 's/"//g')
   title=$(echo $v2 | sed 's/"//g')
   # only open issue if not listed as an open issue
   if ! grep -q ${title} ../open_issues.txt
    then
     echo "The title for ${id} is ${title}."
     gh issue create --title ${title} --body-file ${id}.md
    else
     echo "Issue for project with title '${title}' is already open."
   fi
 done < list_new_projects.txt
 # remove list of new projects after creating the issues - to avoid resubmitting them
 rm list_new_projects.txt # remove file 
fi

