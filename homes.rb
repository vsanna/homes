# require 'nokogiri'
# require 'anemone'

# opts = {
# 	# storage: Anemone::Storage.MongoDB,
# 	depth_limit: 0 
# 		# 0 => 指定したURL先のみ
# 		# 1 => 指定したURLにあるlinkから辿れる先も見る。
# 		# false => 恐らく無限に飛ぶ...
# 		# 「全部のurlから飛ばれちゃ終わらねーよ！」という場合は、focus_crawlで飛びたいURLを指定
# }

# Anemone.crawl("http://www.homes.co.jp/chintai/tokyo/city/price/", opts) do |anemone|
# 	anemone.on_every_page do |page|
# 		page.doc.xpath("/html//div[@class='priceList']//tbody[@id='prg-aggregate-graph']/tr").each do |node|
# 			area  = node.xpath("./td[@class='area']/a/text()").to_s
# 			price = node.xpath("./td[contains(@class,'price')]/div[contains(@class,'money')]/span/text()").to_s
# 			puts area + "：" + price + "万円"
# 			puts "-----------------\n"
# 		end
# 	end
# end

require 'nokogiri'
require 'anemone'

opts = {
	# storage: Anemone::Storage.MongoDB,
	depth_limit: 1
		# 0 => 指定したURL先のみ
		# 1 => 指定したURLにあるlinkから辿れる先も見る。
		# false => 恐らく無限に飛ぶ...
		# 「全部のurlから飛ばれちゃ終わらねーよ！」という場合は、focus_crawlで飛びたいURLを指定
}

Anemone.crawl("http://www.homes.co.jp/chintai/tokyo/city/price/", opts) do |anemone|		
	
	# 起点となるページから飛ぶ先を予め指定
	anemone.focus_crawl do |page|
		page.links.keep_if{|link| link.to_s.match(/http:\/\/www.homes.co.jp\/chintai\/tokyo\/[a-z]*-city\/price\//)}
	end

	# まずは起点ページの地域別賃料を取得
	anemone.on_pages_like(/http:\/\/www.homes.co.jp\/chintai\/tokyo\/city\/price\//) do |page|
		page.doc.xpath("/html//div[@class='priceList']//tbody[@id='prg-aggregate-graph']/tr").each do |node|
			area  = node.xpath("./td[@class='area']/a/text()").to_s
			price = node.xpath("./td[contains(@class,'price')]/div[contains(@class,'money')]/span/text()").to_s
			puts area + "," + price + "万円\n"
		end
	end


	anemone.on_pages_like(/http:\/\/www.homes.co.jp\/chintai\/tokyo\/[a-z]*-city\/price\//) do |page|
		# 地名を取得
		print page.doc.xpath("/html/body//h2/span[@class='key']/text()").to_s + ","
		# 地域別賃料と同様の方法でリスト化
		page.doc.xpath("/html//div[@class='priceList']//tbody[@id='prg-aggregate-graph']/tr").each do |node|
			madori  = node.xpath("./td[@class='madori']/text()").to_s
			price = node.xpath("./td[contains(@class,'price')]/div[contains(@class,'money')]/span/text()").to_s
			# 金額表示無しが目立ったので、priceが空欄の時にはなしと表示
			if price != ""
				puts ",," + madori + "," + price + "万円\n"
			else
				puts ",," + madori + "," + price + "なし\n"
			end
		end
	end

end