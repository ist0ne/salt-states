import os.path

def roles():
    '''define host roles'''

    roles_file = "/etc/salt/roles"
    roles_list = []
  
    if os.path.isfile(roles_file):
        roles_fd = open(roles_file, "r")
        for eachroles in roles_fd:
            roles_list.append(eachroles[:-1])
    return {'roles': roles_list}


if __name__ == "__main__":
    print roles()
