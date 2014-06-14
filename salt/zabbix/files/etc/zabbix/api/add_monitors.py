#!/bin/env python
#coding=utf8

##########################################################
# Add Monitor To Zabbix
##########################################################

import sys, os.path
import yaml

from zabbix.zapi import *

def _config(config_file):
    '''get config'''
    
    config_fd = open(config_file)
    config = yaml.load(config_fd)

    return config

def _get_templates(api_obj, templates_list):
    '''get templates ids'''

    templates_id = {}
    templates_result = api_obj.Template.getobjects({"host": templates_list})
    
    for each_template in templates_result:
        template_name = each_template['name']
        template_id = each_template['templateid']
        templates_id[template_name] = template_id

    return templates_id

def _get_host_templates(api_obj, hostid):
    '''get the host has linked templates'''

    templates_id = []
    templates_result = api_obj.Template.get({'hostids': hostid})
      
    for each_template in templates_result:
        template_id = each_template['templateid']
        templates_id.append(template_id)

    return templates_id


def _create_hostgroup(api_obj, group_name):
    '''create hostgroup'''

    ##check hostgroup exists
    hostgroup_status = api_obj.Hostgroup.exists({"name": "%s" %(group_name)}) 
    if hostgroup_status:
        print "Hostgroup(%s) is already exists" %(group_name)
        group_id = api_obj.Hostgroup.getobjects({"name": "%s" %(group_name)})[0]["groupid"]
    else:
        hostgroup_status = api_obj.Hostgroup.create({"name": "%s" %(group_name)})
        if hostgroup_status:
            print "Hostgroup(%s) create success" %(group_name)
            group_id = hostgroup_status["groupids"][0]
        else:
            sys.stderr.write("Hostgroup(%s) create failed, please connect administrator\n" %(group_name))
            exit(2)

    return group_id

def _create_host(api_obj, hostname, hostip, group_ids):
    '''create host'''

    ##check host exists
    host_status = api_obj.Host.exists({"name": "%s" %(hostname)})
    if host_status:
        print "Host(%s) is already exists" %(hostname)
        hostid = api_obj.Host.getobjects({"name": "%s" %(hostname)})[0]["hostid"]
        ##update host groups
        groupids = [group['groupid'] for group in api_obj.Host.get({"output": ["hostid"], "selectGroups": "extend", "filter": {"host": ["%s" %(hostname)]}})[0]['groups']]
        is_hostgroup_update = 0
        for groupid in group_ids:
            if groupid not in groupids:
                is_hostgroup_update = 1
                groupids.append(groupid)
        if is_hostgroup_update == 1:
            groups = []
            for groupid in groupids:
                groups.append({"groupid": "%s" %(groupid)})
            host_status = api_obj.Host.update({"hostid": "%s" %(hostid), "groups": groups})
            if host_status:
                print "Host(%s) group update success" %(hostname)
            else:
                sys.stderr.write("Host(%s) group update failed, please connect administrator\n" %(hostname))
                exit(3)
    else:
        groups = []
        for groupid in group_ids:
            groups.append({"groupid": "%s" %(groupid)})
        host_status = api_obj.Host.create({"host": "%s" %(hostname), "interfaces": [{"type": 1, "main": 1, "useip": 1, "ip": "%s" %(hostip), "dns": "", "port": "10050"}], "groups": groups})
        if host_status:
            print "Host(%s) create success" %(hostname)
            hostid = host_status["hostids"][0] 
        else:
            sys.stderr.write("Host(%s) create failed, please connect administrator\n" %(hostname))
            exit(3)

    return hostid

def _create_host_usermacro(api_obj, hostname, usermacro):
    '''create host usermacro'''

    for macro in usermacro.keys():
        value = usermacro[macro]

    ##check host exists
    host_status = api_obj.Host.exists({"name": "%s" %(hostname)})
    if host_status:
        hostid = api_obj.Host.getobjects({"name": "%s" %(hostname)})[0]["hostid"]
        ##check usermacro exists
        usermacros = api_obj.Usermacro.get({"output": "extend", "hostids": "%s" %(hostid)})
        is_macro_exists = 0
        if usermacros:
            for usermacro in usermacros:
                if usermacro["macro"] == macro:
                    is_macro_exists = 1
                    if usermacro["value"] == str(value):
                        print "Host(%s) usermacro(%s) is already exists" %(hostname, macro)
                        hostmacroid = usermacro["hostmacroid"]
                    else:
                        ##usermacro exists, but value is not the same, update
                        usermacro_status = api_obj.Usermacro.update({"hostmacroid": usermacro["hostmacroid"], "value": "%s" %(value)})
                        if usermacro_status:
                            print "Host(%s) usermacro(%s) update success" %(hostname, macro)
                            hostmacroid = usermacro_status["hostmacroids"][0]
                        else:
                            sys.stderr.write("Host(%s) usermacro(%s) update failed, please connect administrator\n" %(hostname, macro))
                            exit(3)
                    break
        if is_macro_exists == 0:
            usermacro_status = api_obj.Usermacro.create({"hostid": "%s" %(hostid), "macro": "%s" %(macro), "value": "%s" %(value)})
            if usermacro_status:
                print "Host(%s) usermacro(%s) create success" %(hostname, macro)
                hostmacroid = usermacro_status["hostmacroids"][0]
            else:
                sys.stderr.write("Host(%s) usermacro(%s) create failed, please connect administrator\n" %(hostname, macro))
                exit(3)
    else:
        sys.stderr.write("Host(%s) is not exists" %(hostname))
        exit(3)

    return hostmacroid

def _link_templates(api_obj, hostname, hostid, templates_list, donot_unlink_templates):
    '''link templates'''

    all_templates = []
    clear_templates = []
    ##get templates id
    if donot_unlink_templates is None:
        donot_unlink_templates_id = {}
    else:
        donot_unlink_templates_id = _get_templates(api_obj, donot_unlink_templates)
    templates_id = _get_templates(api_obj, templates_list) 
    ##get the host currently linked tempaltes
    curr_linked_templates = _get_host_templates(api_obj, hostid)
    
    for each_template in templates_id:
        if templates_id[each_template] in curr_linked_templates:
            print "Host(%s) is already linked %s" %(hostname, each_template)
        else:
            print "Host(%s) will link %s" %(hostname, each_template)
        all_templates.append(templates_id[each_template])
    
    ##merge templates list
    for each_template in curr_linked_templates:
        if each_template not in all_templates:
            if each_template in donot_unlink_templates_id.values():
                all_templates.append(each_template)
            else:
                clear_templates.append(each_template)


    ##convert to zabbix api style
    templates_list = []
    clear_templates_list = []
    for each_template in all_templates:
        templates_list.append({"templateid": each_template})
    for each_template in clear_templates:
        clear_templates_list.append({"templateid": each_template})


    ##update host to link templates
    update_status = api_obj.Host.update({"hostid": hostid, "templates": templates_list})

    if update_status:
        print "Host(%s) link templates success" %(hostname)
    else:
        print "Host(%s) link templates failed, please contact administrator" %(hostname)

    ##host unlink templates
    if clear_templates_list != []:
        clear_status = api_obj.Host.update({"hostid": hostid, "templates_clear": clear_templates_list})
        if clear_status:
            print "Host(%s) unlink templates success" %(hostname)
        else:
            print "Host(%s) unlink templates failed, please contact administrator" %(hostname)


def _main():
    '''main function'''
  
    hosts = [] 
    if len(sys.argv) > 1:
        hosts = sys.argv[1:]
    
    config_dir = os.path.dirname(sys.argv[0])
    if config_dir:
        config_file = config_dir+"/"+"config.yaml"
    else:
        config_file = "config.yaml"

    ###get config options
    config = _config(config_file)
    Monitor_DIR = config["Monitors_DIR"]
    Zabbix_URL = config["Zabbix_URL"]
    Zabbix_User = config["Zabbix_User"]
    Zabbix_Pass = config["Zabbix_Pass"]
    Zabbix_Donot_Unlink_Template = config["Zabbix_Donot_Unlink_Template"]

    if not hosts:
        hosts = os.listdir(Monitor_DIR)

    ###Login Zabbix 
    zapi = ZabbixAPI(url=Zabbix_URL, user=Zabbix_User, password=Zabbix_Pass)
    zapi.login()

    for each_host in hosts:
        each_config_fd = open(Monitor_DIR+"/"+each_host) 
        each_config = yaml.load(each_config_fd)
     
        ##Get config options
        each_ip = each_config["IP"]
        hostgroups = each_config["Hostgroup"]
        each_templates = each_config["Templates"]
        each_usermacros = each_config["Usermacros"]

        ###Create Hostgroup
        groupids = []
        for each_hostgroup in hostgroups:
            group_id = _create_hostgroup(zapi, each_hostgroup)
            groupids.append(group_id)

        ##Create Host
        hostid = _create_host(zapi, each_host, each_ip, groupids)

        if each_usermacros:
            ##Create Host Usermacros
            for usermacro in each_usermacros:
                if usermacro:
                    usermacrosid = _create_host_usermacro(zapi, each_host, usermacro)
    
        if each_templates:
            ##Link tempaltes
            _link_templates(zapi, each_host, hostid, each_templates, Zabbix_Donot_Unlink_Template)
           

if __name__ == "__main__":
    _main()

