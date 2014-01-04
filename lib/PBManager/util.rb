require 'net/http'
require 'open3'

require 'pp'
require 'looksee'

# define a few common methods
# they are borderline utility methods, but this is an interim breakout
module PBManager

  def PBManager.download(url, destination)

    PBManager.log.debug("Download: #{url} => #{destination}")
    if File.exist?(destination)
      PBManager.log.debug("Destination exists: #{destination}")
      return
    end

    u = URI.parse(url)
    net = Net::HTTP.new(u.host, u.port)
    case u.scheme
      when "http"
        net.use_ssl = false
      when "https"
        net.use_ssl = true
        net.verify_mode = OpenSSL::SSL::VERIFY_NONE
      else
        raise "Link #{url} is not HTTP(S)"
    end

    net.start do |http|
      File.open(destination, "wb") do |f|
        begin
          http.request_get(u.path) do |resp|
            resp.read_body do |segment|
              f.write(segment)
            end
          end
        rescue => e
          raise PBManager::FatalError.new("Download failed\n#{url} => #{destination}",e)
        end
      end
    end
  end


  def PBManager.verify_download(download, signature)
    crypto = GPGME::Crypto.new
    sign = GPGME::Data.new(File.open(signature))
    file_to_check = GPGME::Data.new(File.open(download))
    crypto.verify(sign, :signed_text => file_to_check, :always_trust => true) do |signature|
      puts "Valid!" if signature.valid?
    end
  end


  # clone a repository to a location
  # note: this refreshes the clone!
  def PBManager.gitclone(source, destination, branch)

    if File.directory?(destination)
      cmd = "cd #{destination} && (git fetch origin '+refs/heads/*:refs/heads/*' && git update-server-info &&  git symbolic-ref HEAD refs/heads/#{branch})"
    else
      cmd = "git clone --bare #{source} #{destination} && cd #{destination} && git update-server-info && git symbolic-ref HEAD refs/heads/#{branch}"
    end

    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|

      PBManager.log.debug("\ngitclone: #{cmd} =>\n#{stdout.read}")

      exit_status = wait_thr.value
      unless exit_status.success?
        raise PBManager::FatalError.new("Cannot pull/clone #{source}\n#{stderr.read}")
      end
    end
  end

end

