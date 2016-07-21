require 'nokogiri'
require 'anemone'

# freezeは今回の話題に関係ありません。書かなくとも問題なし
# 意味がわからないという場合はスルーして下さい

# anemoneの挙動そカスタマイズするoptionです
# 今回はクローリングの深さ(何回リンクをたどるか)を1回と指定しています
OPTS = {
  depth_limit: 1,
  # 0 => 指定したURL先のみ
  # 1 => 指定したURLのページ上にあるlink先も見る(更にその先は見ない)

  delay: 1,
  # ページ訪問間隔を1秒空ける
}.freeze

# 今回クローリングする対象のサイト
BASE_URL = 'http://www.homes.co.jp/chintai/tokyo'.freeze

# 欲しい情報があるhtml要素を指定するxpath
PRICELIST_XPATH = '/html//div[@class="priceList"]//tbody[@id="prg-aggregate-graph"]/tr'.freeze
AREA_XPATH = './td[@class="area"]/a/text()'.freeze
MADORI_XPATH = './td[@class="madori"]/text()'.freeze
PRICE_XPATH = './td[@class="area"]/a/text()'.freeze
PLACE_XPATH = '/html/body//h2/span[@class="key"]/text()'.freeze

Anemone.crawl("#{BASE_URL}/city/price/", OPTS) do |anemone|
  # anemoneは訪問して最初にまずリンクを回収する
  # クロールするたびに、そのページ上のどのリンクを次に訪問するか指定できる
  # 指定した正規表現に該当するリンク先だけにこの後飛んで行く
  anemone.focus_crawl do |page|
    page.links.keep_if { |link| link.to_s.match(%r{#{BASE_URL}/[a-z]*-city/price/}) }
  end

  # on_pages_like: 取得したページのうち、更に、特定のリンク先を指定して飛ぶことができる
  # まずは起点ページの地域別賃料を取得
  anemone.on_pages_like(%r{#{BASE_URL}/city/price}) do |page|
    page.doc.xpath(PRICELIST_XPATH).each do |node|
      area  = node.xpath(AREA_XPATH).to_s
      price = node.xpath(PRICE_XPATH).to_s
      puts area + ',' + price + "万円\n"
    end
  end

  # on_every_page: 取得したページに対して処理を行う 
  # focus_crawlの時点で既に訪問先urlを絞り込んでいるので全てのページに処理を行なう
  anemone.on_every_page do |page|
    # 地名を取得
    print page.doc.xpath(PLACE_XPATH).to_s
    # 地域別賃料と同様の方法でリスト化
    page.doc.xpath(PRICELIST_XPATH).each do |node|
      madori  = node.xpath(MADORI_XPATH).to_s
      price = node.xpath(PRICE_XPATH).to_s
      # 金額表示無しが目立ったので、priceが空欄の時にはなしと表示
      if !price.empty?
        puts ',' + madori + ',' + price + "万円\n"
      else
        puts ',' + madori + ',' + price + "なし\n"
      end
    end
  end

  # after_crawl: クロール後の処理。たとえば取得したデータをdbに保存するなど
  anemone.after_crawl do
    # 保存処理
  end
end
