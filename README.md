## Dead simple GitHub Releases deploy script
It acts as a user shell and knows only two commands `test` and `deploy`. For example, a command

```
ssh deployuser@mega-server test myproject tag.0.0.123
``` 

will evaluate following tasks:
- asdf


### Limitations and todo
- Basic auth
- It gets the first asset from assets array. (some logic should be added here, may be filename in config or something, e.g: 'release-file-name':'release.zip')
- per project exclusion list in config
- per project after installation tasks (e.g.: forever restart, etc...)
- check tag. Now, if tag is not found, script will fail with ugly html output.
- multiproject support only for github organization.

### Configuration
`deploy-cfg.json` should be in same directory

```javascript
{
	"credentials"   : "someuser:somepassword",
	"github_root"   : "github_organization_or_repo_name",
	"projects"      : "project1 project2 site-v2",
	"projects_home" : "/tmp/home"
}
```

@todo some comments about github organization and repo structure...

### Installation
- Create deploy user by running something like this (should work on most linux systems)

```sh
adduser --home /home/deploy --shell /home/someone/deploy.sh
```
- Put `deploy.sh` and `deploy-cfg.json` into the `/home/deploy` and run:

```
chmod +x /home/deploy/deploy.sh
```
	
- create projects home and ensure that it's writable for deploy user. e.g.: 
```
mkdir /opt/wwwhome
chown deploy /opt/wwwhome
```

- Edit `deploy-cfg.json`

### Usage
Command `test`
```
ssh deploy@your_server test project_name tag_name
```
It will do following stuff:
- get list of GitHub releases from `api.github.com/repos/{organization_name}/{project_name}/releases`
- get first url from asset with `tag_name`
- download and unpack it to `{project_name}/rc`
- rsync it to `PROJECTS_HOME/{project_name}-test/`

Command `deploy`
   - sync `PROJECTS_HOME/{project_name}-test/` with `PROJECTS_HOME/{project_name}-prod/`

### Adding more projects
Just add a name to projects list. And upload release.zip to the github.
