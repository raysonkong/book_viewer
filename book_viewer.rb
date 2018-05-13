require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

before do 
  @contents = File.readlines("data/toc.txt")
end

helpers do
	def format_text(text)
		text.split("\n\n").each_with_index.map do |paragraph, index|
		  "<p id=paragraph#{index}>#{paragraph}</p>"
		end.join
	end

	def highlight(text, term)
		text.gsub(term, "<strong>#{term}</strong>")
	end
end

get '/' do
	@title = "The Adventure of Sherlock Holmes"
	erb(:home)
end

get '/chapters/:number' do
	number = params[:number].to_i
	redirect '/' unless (1..@contents.size).cover?(number)

	@title = "Ch#{number}: #{@contents[number - 1]}"
	@chapter_content = File.read("data/chp#{number}.txt")
	erb(:chapters)
end

def each_chapter
	@contents.each_with_index do |title, index|
		chp_number = index + 1
		chp_content = File.read("data/chp#{index + 1}.txt")

		yield chp_number, title, chp_content
	end
end

def chapters_matching(query)
  # input: chp_number, chp_title, chp_contents
  # output: [{chp_number, chp_title}] where chp_content contains query
  results = []

  return results unless query

  each_chapter do |number, title, contents|
  	matches = {}
  	contents.split("\n\n").each_with_index do |paragraph, index|
  		matches[index] = paragraph if paragraph.include?(query)
  	end
  	results << {number: number, title: title, paragraphs: matches} if matches.any?
  end

  results
end

get '/search' do
	@results = chapters_matching(params[:query])
	# @results = [{ :number=> chp_number, :title => chp_title, :paragraphs => matches_hash }, {}]
	# usage: @results.each do |result|
	#   result[:number], result[:title]
	#   result[:paragraphs] => {para no => para, 1 => para1, 2 => para2...}
	erb(:search)
end

not_found do
	redirect '/'
end
