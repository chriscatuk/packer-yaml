# Packer YAML

Add an abstraction layer to Packer via a YAML file.

## Requirements
Python 3 venv installation:

``` bash
python3 -m venv venv
source venv/bin/activate
pip3 install --upgrade pip
```


``` bash
#To begin using the virtual environment, it needs to be activated:
source venv/bin/activate
```

``` bash
# To desactivate the virtual environment for Python
deactivate
```

Use the requirements.txt file to install packages
``` bash
pip3 install -r requirements.txt
```

And use this commandline to produce template
``` bash
 ansible-playbook test.yml  -e @automation/config/vpc.yml -e @automation/config/aws.yml -i localhost
```