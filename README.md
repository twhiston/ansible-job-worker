# Ansible Job Worker

Ansible job worker is a container that can pull external ansible playbook repositories and action them as openshift jobs.

It works as a s2i image builder style image which means that you only have a single image for all your projects jobs
and using openshifts repository hooks can easily be rebuilt on commit.


## Usage

Create an s2i builder in openshift, if you have the permissions you can pull it from source
```
oc new-app https://github.com/twhiston/ansible-job-worker.git --context-dir="context/prod" --name="ajw-builder"
#we dint need a dc for this
oc delete dc ansible-job-runner-builder
```
or pull it as a docker image from docker hub.


When the s2i image builds your project it looks for certain things during the build process that allow
you to action additional build requirements  such as generating keys, configuring modules, running sync and logging processes
or copying secrets mounted from openshift into the build container (if you do this never store your image in a public repository)

Therefore to get ajw working properly you will need to add some files to your ansible project

In your project root create a folder  called `.ajw`

The folder may contain the following folders


* cronjobs:
        contains openshift cronjob templates (currently not used directly but in roadmap of golang cli tool)
        see [Openshift Documentation](https://docs.openshift.org/latest/dev_guide/cron_jobs.html)


* jobs:
        contains openshift cronjob templates (currently not used directly but in roadmap of golang cli tool)
        see [Openshift Documentation](https://docs.openshift.org/latest/dev_guide/jobs.html)


* scripts:
        contains scripts to be used at container assembly time by the s2i image.
        The only scripts that will be called directly are:
        
            `build.sh` - run after the source is copied and the basic ansible setup is done
            `permissions.sh` - run after fix-permissions.sh is run over the home folder to allow manual correction if needed
            `test.sh` - put any tests that you want to run after the image has been build here, run after permissions.sh
            `cleanup.sh` - put any cleanup code here, run directly at the end of the assemble script


* secrets:
        openshift templates for secrets. It is STRONGLY advised that this folder is .gitignored and not shared, and is purely kept here out of convenience.


Once these files are added you can create the app in openshift (add and configure source secrets if your repo is private)

`oc new-app ajw-builder~https://github.com/my-name/my-ansible-repo.git `

once again you should delete the dc as you will never deploy this image outside of jobs
`oc delete dc myansiblerepo`

At this point, provided all your build scripts returned successfully you should have a fully built container to start executing jobs in
and all you need to do is add them with `oc generate -f my-job-definition.yml`

If your ansible script calls something that gets your username or user id you will need to wrap your call to ansible in a script
provided by the container. To use this specify your job as follows
`command: ["/opt/app-root/src/container-entrypoint", "ansible-playbook",  "-i", "ec2.py", "install.yml"]`
This will be turned into something more user friendly soon! If you use this container locally you do not need to wrap your command calls
as this script is also the default container entrypoint, which is not respected in openshift.

## Full job example

This is an example cronjob definition, where elements in {braces} denotes something project specific

```
apiVersion: batch/v2alpha1
kind: CronJob
metadata:
  name: {project-id}-sync
spec:
  schedule: "*/30 * * * *"
  jobTemplate:
    spec:
      activeDeadlineSeconds: 300
      template:
        metadata:
          labels:
            parent: "{PROJECT-ID}-sync"
            kind: "cronjob"
        spec:
          containers:
          - name: server-install
            image: {my-project-namespace}/{my-project-build-s2i-image-name}
            command: ["/opt/app-root/src/container-entrypoint", "ansible-playbook",  "-i", "ec2.py", "sync.yml"]
          restartPolicy: Never
```
