class Person
  module PdfGen
    def generate_directory_pdf(with_pictures=false)
      pdf = PDF::Writer.new
      pdf.margins_pt 70, 20, 20, 20
      pdf.open_object do |heading|
        pdf.save_state
        pdf.stroke_color! Color::RGB::Black
        pdf.stroke_style! PDF::Writer::StrokeStyle::DEFAULT

        size = 24

        x = pdf.absolute_left_margin
        y = pdf.absolute_top_margin + 30
        pdf.add_text x, y, "#{Setting.get(:name, :church)} Directory\n\n", size

        x = pdf.absolute_left_margin
        w = pdf.absolute_right_margin
        #y -= (pdf.font_height(size) * 1.01)
        y -= 10
        pdf.line(x, y, w, y).stroke

        pdf.restore_state
        pdf.close_object
        pdf.add_object(heading, :all_following_pages)
      end

      s = 24
      w = pdf.text_width(Setting.get(:name, :church), s)
      x = pdf.margin_x_middle - w/2 # centered
      y =  pdf.absolute_top_margin - 150
      pdf.add_text x, y, Setting.get(:name, :church), s
      s = 20
      w = pdf.text_width('Directory', s)
      x = pdf.margin_x_middle - w/2 # centered
      y =  pdf.absolute_top_margin - 200
      pdf.add_text x, y, 'Directory', s

      # disable for now, until we can ensure 16bit pngs don't blow up
      # if Setting.get(:appearance, :logo).to_s.any?
      #   logo_path = "#{Rails.root}/public/images/#{Setting.get(:appearance, :logo)}"
      #   if File.exist?(logo_path) and img = MiniMagick::Image.from_blob(File.read(logo_path)) rescue nil
      #     pdf.add_image img.to_blob, pdf.margin_x_middle - img['width']/2, pdf.absolute_top_margin - 200
      #   end
      # end

      t = "Created especially for #{self.name} on #{Date.today.strftime '%B %e, %Y'}"
      s = 14
      w = pdf.text_width(t, s)
      x = pdf.margin_x_middle - w/2 # centered
      y = pdf.margin_y_middle - pdf.margin_height/3 # below center
      pdf.add_text x, y, t, s

      pdf.start_new_page
      pdf.start_columns

      alpha = nil

      Family.find(
        :all,
        :conditions => ["(select count(*) from people where family_id = families.id and visible_on_printed_directory = ?) > 0", true],
        :order => 'families.last_name, families.name, people.sequence',
        :include => 'people'
      ).each do |family|
        if family.mapable? or family.home_phone.to_i > 0
          pdf.move_pointer 120 if pdf.y < 120
          if family.last_name[0..0] != alpha
            if with_pictures and family.has_photo?
              pdf.move_pointer 450 if pdf.y < 450
            else
              pdf.move_pointer 150 if pdf.y < 150
            end
            alpha = family.last_name[0..0]
            pdf.text alpha + "\n", :font_size => 25
            pdf.line(
              pdf.absolute_left_margin,
              pdf.y - 5,
              pdf.absolute_left_margin + pdf.column_width - 25,
              pdf.y - 5
            ).stroke
            pdf.move_pointer 10
          end
          if with_pictures and family.has_photo?
            pdf.move_pointer 300 if pdf.y < 300
            pdf.add_image File.read(family.photo_large_path), pdf.absolute_left_margin, pdf.y-150, nil, 150
            pdf.move_pointer 160
          end
          pdf.text family.name + "\n", :font_size => 18
          if family.people.length > 2
            p = family.people.map do |p|
              p.last_name == family.last_name ? p.first_name : p.name
            end.join(', ')
            pdf.text p + "\n", :font_size => 11
          end
          if family.share_address_with(self) and family.mapable?
            pdf.text family.address1 + "\n", :font_size => 14
            pdf.text family.address2 + "\n" if family.address2.to_s.any?
            pdf.text family.city + ', ' + family.state + '  ' + family.zip + "\n"
          end
          pdf.text ApplicationHelper.format_phone(family.home_phone), :font_size => 14 if family.home_phone.to_i > 0
          pdf.text "\n"
        end
      end

      pdf
    end

    def generate_directory_pdf_to_file(filename, with_pictures=false)
      File.open(filename, 'wb') { |f| f.write(generate_directory_pdf(with_pictures)) }
    end
    
    def generate_and_email_directory_pdf(with_pictures=false)
      filename = "#{Rails.root}/tmp/directory_for_user#{id}.pdf"
      generate_directory_pdf_to_file(filename, with_pictures)
      Notifier.deliver_printed_directory(self, File.open(filename))
    end
  end
end
