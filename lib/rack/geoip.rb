#
# Author:: Benjamin Black (<bb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# rack middleware to do ip to geo lookups on client addresses via the maxmind
# database.
#
# the maxmind geoip.bundle file either needs to live in the right place in the
# system ruby directories or in lib/net/ .  it was such a pain to get properly built
# on osx that i found both options useful.
#
# the maxmind database can be specified using the :geodb_path argument.  the
# default is /usr/local/share/GeoIP/GeoLiteCity.dat .
#

$:.unshift File.expand_path(File.dirname(__FILE__)) + '../net/'

require 'rack'
require 'net/geoip'

module Rack
	class GeoIP
	  attr_reader :geodb
	  
    def initialize(app, geodb_path = "/usr/local/share/GeoIP/GeoLiteCity.dat")
      @app = app
      @geodb = Net::GeoIP.new(geodb_path)
    end

    def call(env)
      begin
        rec = geodb[env["REMOTE_ADDR"]]
        env['geoip.country_code'] = rec.country_code
        env['geoip.region'] = rec.region
        env['geoip.city'] = rec.city
        env['geoip.latitude'] = rec.latitude
        env['geoip.longitude'] = rec.longitude
      rescue Net::GeoIP::RecordNotFoundError
        env['geoip.country_code'] =
        env['geoip.region'] =
        env['geoip.city'] =
        env['geoip.latitude'] =
        env['geoip.longitude'] = nil
      end
      
      @app.call(env)
      
      # for testing:
      # ops = env.inject({}) { |memo, kv| kv[0].match(/^geoip\./) ? memo[kv[0]] = kv[1] : nil ; memo }
      # [200, {'Content-Type' => 'text/html', 'Content-Length' => (ops.to_yaml.length + 1).to_s}, ["#{ops.to_yaml}\n"]]
    end
    
  end
end