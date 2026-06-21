AdminBootstrap.call

SiteSetting.instance
%w[Shelf A1 Shelf B2].each_with_index do |name, index|
  Location.find_or_create_by!(name: name) { |location| location.position = index }
end

if Book.none?
  shelf_a1 = Location.find_by!(name: 'Shelf A1')
  shelf_b2 = Location.find_by!(name: 'Shelf B2')

  Books::Save.new(Book.new, {
                    title: 'Make: Electronics',
                    author_names_text: "Charles Platt\n",
                    location_id: shelf_a1.id,
                    notes: 'Getting started with electronics at the hackerspace.',
                    isbn_codes: []
                  }).call

  Books::Save.new(Book.new, {
                    title: 'The Pragmatic Programmer',
                    author_names_text: "David Thomas\nAndrew Hunt\n",
                    published_on: Date.new(1999, 10, 30),
                    location_id: shelf_b2.id,
                    isbn_codes: ['9780201616224']
                  }).call
end
