client = Octokit::Client.new(access_token: "SECRET PAT")

q = "#{query} repo:#{repositry} language:markdown"

client.search_code(q).items


