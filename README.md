# Automatic Lynis Report
`alr` is a bash wrapper for lynis: the goal is to automate the process of lynis report for organizations that have a fleet of linux endpoints that want to assess from a security point of view.

The script does:
- check if lynis is installed. If not, it will clone the repository
- run lynis with a custom profile if provided
- apply a group and a label to the report. This is useful if you want to group machines by organitations and labels
- upload to the lynis web ui if `REMOTE_UPLAOD=1` (default `0`)


# Usage
As simply as:
```
$ git clone https://github.com/dab-solutions/alr.git
$ cd alr
~/alr$ bash alr.sh dabtechsolutions davide-laptop
```
## Custom profiles
If you want to provide a custom profile, just save it next to the `alr.sh` script and call it `custom.prf` as shown below.

```
~/alr$ tree
.
├── alr.sh
├── custom.prf
└── README.md

0 directories, 3 files
~/alr$
```

`alr` will automatically use it instead of the default one.

## Remote upload
To enable remote upload to a lynis web ui instance, do the following:
```
~/alr$ export ALR_REMOTE_SERVER="https://lynis-web-ui.endpoint"
~/alr$ sed -i 's/REMOTE_UPLOAD=0/REMOTE_UPLOAD=1/' alr.sh
~/alr$ bash alr.sh dabtechsolutions davide-laptop
```
