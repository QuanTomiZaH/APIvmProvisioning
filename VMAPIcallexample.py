# import
import requests
import base64
import json


# getting the certificate to do api calls
def get_certificate(base64auth):
    # there is no try / expect here yet. add this in case credentials are incorrect
    try:
        print("Getting authentication token")
        endpoint = "<URL>"
        headers = {
            "Authorization": base64auth
        }
        print(headers)
        r = requests.get(endpoint, headers=headers, verify=False)
        r = r.text

        print(r)
        # splitting the text so only the token will be returned to be used
        authentication = r.split(",", 1)
        authentication = authentication[0].split(":")
        token = authentication[1]
        token = token[1:-1]
        print("Authentication token gained")

    except:
        print("Something went wrong with gaining the token / authorization")
        
    return token


# a function to check if the credentials/api is working as intended
def check_api(header):
    # trying the general API call
    endpoint = "<URL>"

    try:
        r = requests.get(endpoint, headers=header, verify=False)
        print(r.status_code)
        print("The API / credentials are working as intended")
    except:
        print("There is an error")


# the function to provision a RancherOS VM
def rancher_os_provisioning(auth, vm_name, yaml_location, datacenterlocation):
    cloudconfig = yaml_to_string(yaml_location)
    # these variables have to be defined in the Azure Devops pipeline, these are placeholders
    vlan = "<VLAN>"
    iso = "<ISO>"
    environment = "<ENV>"
    businesscrit = "<State>"

    # provide the endpoint and payload(configuration)
    endpoint = "<URL>"

    # Change the variables in the Json Request
    with open("RancherOSconfig.json", "r") as json_file:
        payload = json.load(json_file)

        #this can still be a lot nicer, but it works for now
        try:
            payload["vm_name"] = payload["vm_name"].replace("r", vm_name)
            payload["location"] = payload["location"].replace("r", datacenterlocation)
            payload["vlan"] = payload["vlan"].replace("r", vlan)
            payload["iso"] = payload["iso"].replace("r", iso)
            payload["cloud_config"] = payload["cloud_config"].replace("r", cloudconfig)
            # edit the tags
            tags = payload["tags"]
            tags["environment"] = tags["environment"].replace("r", environment) 
            tags["business_critical"] = tags["business_critical"].replace("r", businesscrit)
            payload["tags"] = tags
        except TypeError:
            print("error in editing the JSON file")
    
    # Provision a RancherOS VM
    try:
        r = requests.post(endpoint, headers=auth, json=payload, verify=False)
        print("Succesfully posted to the API")
        print(r.status_code)
        print(r.text)

    except TypeError:
        r = requests.post(endpoint, headers=auth, json=payload, verify=False)
        print("TypeError, check to fix")
        print(r.status_code)

    return r


# Makeing the credentials base64 encoded so they can be used to authorize in the API
def base64_encode():
    data = "<credentials>"
    encoded_credentials = base64.b64encode(data.encode("utf-8"))
    encoded_credentials_str = str(encoded_credentials, "utf-8")
    encoded_credentials_str = "Basic " + encoded_credentials_str
    return encoded_credentials_str


# convert a yaml to a one line string to send to an API
def yaml_to_string(location):
    with open(location, "r") as o:
        data = o.read()
    return data

# the main sequence to enact
def main():
    
    yaml_location = "cloud-config.yaml"
    # These variables are placeholders, these have to be replaced in the Azure Devops pipeline
    vm_name = "<vmname>"

    datacenterlocation = "<location>"

    # base64token
    cred = base64_encode()

    # endpoint
    token = get_certificate(cred)
    print("The token = " + token)
    headers = {
        "X-Auth-Token": token
    }

    # check if the API / Credentials are working
    check_api(headers)

    # here will be calling the post etc functions
    rancher_os_provisioning(headers, vm_name, yaml_location, datacenterlocation)

    print("Virtual Machine provisioned")


# execute the program
if __name__ == '__main__':
    main()
