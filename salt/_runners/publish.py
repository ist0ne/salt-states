# -*- coding: utf-8 -*-
'''
Functions to publish code on the master
'''

# Import salt libs
import salt.client
import salt.output


def push(project, output=True):
    '''
    publish code to web server.

    CLI Example:

    .. code-block:: bash

        salt-run publish.push project
    '''

    client = salt.client.LocalClient(__opts__['conf_file'])
    ret = client.cmd(__opts__['publish']['master'],
                      'svn.checkout',
                       [
                         __opts__['publish']['cwd'],
                         __opts__['projects'][project]['remote']
                       ],
                       {
                         'username': __opts__['svn']['username'],
                         'password':__opts__['svn']['password']
                       }
                    )

    msg = 'URL: %s\n%s' %(__opts__['projects'][project]['remote'], ret[__opts__['publish']['master']])
    ret = {'Check out code': msg}
    if output:
        salt.output.display_output(ret, '', __opts__)

    for target in __opts__['projects'][project]['target']:
        cmd = '/usr/bin/rsync -avz --exclude=".svn" %s/%s/trunk/* %s/' %(__opts__['publish']['cwd'], project, target)
        ret[target] = client.cmd(__opts__['publish']['master'],
                           'cmd.run',
                           [
                             cmd,
                           ],
                         )

        title = '\nSending file to %s' %target.split(':')[0]
        ret = {title: ret[target][__opts__['publish']['master']]}
        if output:
            salt.output.display_output(ret, '', __opts__)

    return ret
