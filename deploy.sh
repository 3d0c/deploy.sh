#!/bin/bash

DEPLOY_CFG="deploy-cfg.json"

test() {
	"$@"
	
	local status=$?
	if [ $status -ne 0 ]; then
		echo "error with $1"
		exit -1

	fi

	return $status
}

# unused
upvar() {
	if unset -v "$1"; then
		if (( $# == 2 )); then
			eval $1=\"\$2\"
		else
			eval $1=\(\"\${@:2}\"\)
		 fi
	fi
}

# unused
set_val () {
	local "$1" && upvar $1 $2
}

contains() {
	for word in $1; do
		[[ $word == $2 ]] && return 0
	done

	return 1
}

release_uri() {
	if [ -z "$1" ]
	then
		echo "arg1 is expected valid repository name"
		exit -1
	fi

	if [ -z "$2" ]
	then
		echo "arg2 is expected valid TAG"
		exit -1
	fi

	uri=`curl -s -H "Accept: application/vnd.github.manifold-preview" -u "$CREDENTIALS" https://api.github.com/repos/$REPONAME/$1/releases | python -c "import sys; import json; data = json.load(sys.stdin); print filter(lambda y: y['tag_name'] == '$2', map(lambda x: x, data))[0]['assets'][0]['url']" 2> /dev/null`

	if [ $? -ne 0 ]; then
		echo "Unable to get release url for https://api.github.com/repos/$REPONAME/$1/releases tag: $2"
		exit -1
	fi

	echo $uri
}

get_json_field() {
	val=`python -c "import sys; import json; fp = open('$DEPLOY_CFG'); data = json.load(fp); print data['$1'] if data.get('$1') else sys.exit(1)"`

	if [ $? -ne 0 ]; then
		echo ""
	fi

	echo $val
}

IFS=' ' read -a input <<< "$2"

# echo "Project: '${input[1]}', command: '${input[0]}', tag: '${input[2]}'"

PROJECT=${input[1]}
COMMAND=${input[0]}
TAG=${input[2]}

if [ ! -f $DEPLOY_CFG ]; then
	echo "No deploy-cfg.json found"
	exit -1
fi

REPONAME=$(get_json_field "reponame")
CREDENTIALS=$(get_json_field "credentials")
PROJECTS="$(get_json_field 'projects')"
PROJECTS_HOME=$(get_json_field "projects_home")

show_cfg() {
	echo -e "\nREPONAME: "$REPONAME
	echo "CREDENTIALS: "$CREDENTIALS
	echo "PROJECTS: ""$PROJECTS"
	echo "PROJECTS_HOME: "$PROJECTS_HOME
	echo -e "\n$DEPLOY_CFG"
	
	cat $DEPLOY_CFG 
}

if [ -z "$REPONAME" ] || [ -z "$CREDENTIALS" ] || [ -z "$PROJECTS" ] || [ -z "$PROJECTS_HOME" ];then
	echo -e "\nError: Wrong config."
	show_cfg
	exit -1
fi

if [ "$COMMAND" == "config" ];then
	show_cfg
	exit 0
fi

if ! contains "$PROJECTS" "$PROJECT"; then
	echo -e "\nError: Project not found"
	exit -1
fi

if [ "$COMMAND" == "test" ];then
	if [ -z "$TAG" ]; then
		echo "Please provide a valid tag."
		exit -1
	fi

	project_home=$PROJECT"-test"

	test rm -rf $PROJECT/rc && rm -f $PROJECT/release.zip && mkdir -p $PROJECT/rc

	test curl -s -o $PROJECT/release.zip -L -u $CREDENTIALS -H "Accept: application/octet-stream" $(release_uri "$PROJECT" "$TAG")
	
	test unzip -qq $PROJECT/release.zip -d $PROJECT/rc

	if [ ! -d "$PROJECTS_HOME/$project_home" ]; then
		test mkdir -p $PROJECTS_HOME/$project_home
	fi

	test rsync -cr --delete $PROJECT/rc/* $PROJECTS_HOME/$project_home

	# Surely you have to start it before. Or do some tests here.
	# forever restart $PROJECTS_HOME/$project_home/app.js
	
	echo "Success. Test version has been deployed."
	exit
fi

if [ "$COMMAND" == "deploy" ];then
	project_home=$PROJECT"-prod"

	if [ ! -d "$PROJECTS_HOME/$project_home" ]; then
		mkdir -p $PROJECTS_HOME/$project_home
	fi

	if [ ! -d $PROJECTS_HOME/$PROJECT"-test" ]; then 
		echo "Run 'test' command before 'deploy'."
		exit -1
	fi

	# exclude flag is just for example
	# copy from test location to production
	test rsync -cr --delete --exclude="config.json" $PROJECTS_HOME/$PROJECT"-test"/* $PROJECTS_HOME/$project_home
	
	# Surely you have to start it before. Or do some tests here.
	# forever restart $PROJECTS_HOME/$project_home/app.js

	echo "Success. Project has been deployed."
	exit
fi
