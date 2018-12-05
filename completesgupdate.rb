#!/usr/bin/env ruby
require 'right_api_client'
puts "Input RightScale Cloud Env (Dev or Prod)"
en = gets.chomp.downcase
if en == "dev"
	@client = RightApi::Client.new(:api_url => "https://us-4.rightscale.com", :account_id => "13465", :refresh_token => "c19c715936f8f2b1e796b258541096f699239648")
elsif en == "prod"
	@client = RightApi::Client.new(:api_url => "https://us-3.rightscale.com", :account_id => "7453", :refresh_token => "6f8906d3475573d9a09fa1229a9fdbbac67b861b")
else
	puts "Please enter Dev or Prod only"
end
puts "Please provide deployment id: [eg:- dev340, prd320, dev256]"
$deployment_id = gets.chomp
puts "Please provide server type you want to add the Security groups to: [eg:- utl1, utl2, dbm, dbs1]"
$type = gets.chomp
def get_cloud_id()
    cloud_id = nil
	deployment = @client.deployments.index(:filter => ["name==#{$deployment_id}"])
	deployment.first.servers.index.each do |server|
		current_instance_type = ""
		if server.show.name == "#{$deployment_id}#{$type}"
			server.current_instance.show(:view => 'extended').links.each do |link|
			current_instance_type = link["href"] unless link["rel"] != "instance_type"
			end
		cloud_id = current_instance_type.split('/')[3].to_i
		end
	end
	return cloud_id
end

def update_security_groups(cloud_id)
        puts "Input comma separated securitygroup: [eg:- devvpc2-dbsg, devvpc2-intsg]"
        securitygroup = gets.chomp.delete(' ')
        cloud = @client.clouds(:id => "#{cloud_id}").show
        sg_href = []
    securitygroup.split(',').each { |sg|
      begin
        sg_href << cloud.security_groups.index(:filter => ["name==#{sg}"]).first.href
      rescue => e
        puts "Fetching href for #{sg} failed with below error : \n #{e.message}"
      end
        }
    	deployment = @client.deployments.index(:filter => ["name==#{$deployment_id}"])
    	deployment.first.servers.index.each do |server|
			if server.show.name == "#{$deployment_id}#{$type}"
				server.next_instance.update(:instance => {:security_group_hrefs => [sg_href]})
			end
		end


end
update_security_groups(get_cloud_id)
