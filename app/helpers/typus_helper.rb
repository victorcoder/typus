module TypusHelper

  MODELS = YAML.load_file("#{RAILS_ROOT}/config/typus.yml")

  def head
    @block = "<title>#{TYPUS['app_name']} &rsaquo; #{page_title}</title>\n"
    @block += "<link rel=\"shortcut icon\" href=\"/favicon.ico\" type=\"image/x-icon\" />\n"
    @block += "<meta http-equiv=\"imagetoolbar\" content=\"no\" />\n"
    @block += "<meta name=\"description\" content=\"\" />\n"
    @block += "<meta name=\"keywords\" content=\"\" />\n"
    @block += "<meta name=\"author\" content=\"\" />\n"
    @block += "<meta name=\"copyright\" content=\"\" />\n"
    @block += "<meta name=\"generator\" content=\"\" />\n"
    @block += "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n"
    @block += stylesheet_link_tag "typus", :media => "screen"
    @block += "\n"
    @block += javascript_include_tag :defaults
    return @block
  end

  def header
    @block = "<h1>#{TYPUS['app_name']}"
    @block += "<span class=\"feedback\">#{flash[:notice]}</span>" if flash[:notice]
    @block += "</h1>\n"
    @block += "<h2>#{TYPUS['app_description']}</h2>"
    return @block
  end

  def breadcrumbs
    @block = ""
    if params[:model]
      @block += "<p>"
      @block += "<a href=\"/#{TYPUS['prefix']}/\">Home</a>"
      case params[:action]
      when "index"
        @block += " &rsaquo; #{params[:model].capitalize}</li>\n"
      when "edit"
        @block += " &rsaquo; <a href=\"/#{TYPUS['prefix']}/#{params[:model]}\">#{params[:model].capitalize}</a></li>\n"
        @block += " &rsaquo; Edit</li>\n"
      when "new"
        @block += " &rsaquo; <a href=\"/#{TYPUS['prefix']}/#{params[:model]}\">#{params[:model].capitalize}</a></li>\n"
        @block += " &rsaquo; New</li>\n"
      end
      @block += "</p>"
    end
    return @block
  end

  def modules
    @block = "<ul>\n"
    MODELS.each { |model| @block += "<li><a href=\"/#{TYPUS['prefix']}/#{model[0].downcase.pluralize}\">#{model[0].pluralize}</a> <small><a href=\"/#{TYPUS['prefix']}/#{model[0].downcase.pluralize}/new\">Add</a></small><br />#{model[1]['copy']}</li>\n" }
    @block += "</ul>\n"
    return @block
  rescue
    return "<ul><li>FixMe: <strong>typus.yml</strong></li></ul>"
  end

  def sidebar
    if params[:model]
      @model = eval params[:model].singularize.capitalize
      
      # Default Actions
      @block = "<h2>Actions</h2>\n"
      case params[:action]
      when "index"
        @block += "<ul>\n"
        @block += "<li><a href=\"/#{TYPUS['prefix']}/#{params[:model]}/new\">Add new #{params[:model].singularize}</a></li>\n"
        @block += "</ul>\n"
      when "new"
        @block += "<ul>\n"
        @block += "<li><a href=\"/#{TYPUS['prefix']}/#{params[:model]}\">Back to list</a></li>\n"
        @block += "</ul>\n"
      when "edit"
        @block += "<ul>\n"
        @block += "<li>#{link_to "Next #{params[:model].singularize}", :action => "edit", :id => @next.id}</li>" if @next
        @block += "<li>#{link_to "Previous #{params[:model].singularize}", :action => 'edit', :id => @previous.id}</li>" if @previous
        @block += "</ul>\n"
        @block += "<ul>\n"
        @block += "<li><a href=\"/#{TYPUS['prefix']}/#{params[:model]}\">Back to list</a></li>\n"
        @block += "</ul>\n"
      end
      
      # Extra Actions
      if MODELS[@model.to_s]["actions"]
        @block += "<h2>More Actions</h2>"
        @block += "<ul>"
        @model.actions.each { |a| @block += "<li><a href=\"/#{TYPUS['prefix']}/#{params[:model]}/#{a[0]}\">#{a[0].humanize}</a></li>" if a[1] == params[:action] }
        @block += "</ul>"
      end
      
      # Search
      if params[:action] == "index"
        if MODELS[@model.to_s]["search"]
          @block += "<h2>Search</h2>\n"
          @block += "<form action=\"/#{TYPUS['prefix']}/#{params[:model]}\" method=\"get\">"
          @block += "<p><input id=\"q\" name=\"q\" type=\"text\" value=\"#{params[:q]}\"/></p>"
          @block += "</form>"
        end
      end
      
      # Filters (only shown on index page)
      if params[:action] == "index"
        if MODELS[@model.to_s]["filters"]
          @block += "<h2>Filter</h2>"
          @model.filters.each do |f|
            case f[1]
            when "boolean"
              @current_request = (request.env['QUERY_STRING']) ? request.env['QUERY_STRING'].split("&") : []
              @block += "<h3>By #{f[0].humanize}</h3>\n"
              @block += "<ul>\n"
              @status = params[:status] == "true" ? "on" : "off"
              @block += "<li><a class=\"#{@status}\" href=\"/#{TYPUS['prefix']}/#{params[:model]}?#{f[0]}=true&#{(@current_request.delete_if { |x| x.include? "#{f[0]}" }).join("&")}\">Active</a></li>\n"
              @status = params[:status] == "false" ? "on" : "off"
              @block += "<li><a class=\"#{@status}\" href=\"/#{TYPUS['prefix']}/#{params[:model]}?#{f[0]}=false&#{(@current_request.delete_if { |x| x.include? "#{f[0]}" }).join("&")}\">Inactive</a></li>\n"
              @block += "</ul>\n"
            when "datetime"
              @block += "<h3>By #{f[0].humanize}</h3>\n"
              @block += "<ul>\n"
              @filters = %w(today past_7_days this_month this_year)
              @filters.each do |timeline|
                @status = params[:created_at] == timeline ? "on" : "off"
                @current_request = (request.env['QUERY_STRING']) ? request.env['QUERY_STRING'].split("&") : []
                @block += "<li><a class=\"#{@status}\" href=\"/#{TYPUS['prefix']}/#{params[:model]}?#{f[0]}=#{timeline}&#{(@current_request.delete_if { |x| x.include? "#{f[0]}" }).join("&")}\">#{timeline.humanize.capitalize}</a></li>\n"
              end
              @block += "</ul>\n"
            when "collection"
              @block += "<h3>By #{f[0].humanize}</h3>"
              @model = eval f[0].capitalize
              @block += "<ul>\n"
              @model.find(:all).each { |item| @block += "<li><a href=\"/#{TYPUS['prefix']}/#{params[:model]}?#{f[0]}_id=#{item.id}\">#{item.name}</a></li>\n" }
              @block += "</ul>\n"
            end
          end
        end
      end
    end
    return @block
#  rescue
#    return "FixMe: <strong>typus.yml</strong>"
  end

  def feedback
    if flash[:notice]
      "<div id=\"notice\">#{flash[:notice]}</div>"
    elsif flash[:error]
      "<div id=\"notice-error\">#{flash[:error]}</div>"
    end
  end

  def page_title
    "#{params[:model].capitalize if params[:model]} #{"&rsaquo;" if params[:model]} #{params[:action].capitalize if params[:action]}"
  end

  def footer
    @block = "<p><a href=\"http://intraducibles.net/work/typus\">Typus #{TYPUS["Typus"]["version"]}</a></p>"
  end

  def fmt_date(date)
    date.strftime("%d.%m.%Y")
  end

  def typus_form
    @block = ""
    @block += error_messages_for :item, :header_tag => "h3"
    @form_fields.each do |field|
      @block += "<p><label>#{field[0].humanize}</label>"
      case field[1]
      when "string"
        @block += text_field :item, field[0], :class => "big"
      when "text"
        @block += text_area :item, field[0], :rows => "#{field[2]}"
      when "datetime"
        @block += datetime_select :item, field[0]
      when "password"
        @block += password_field :item, field[0], :class => "big"
      when "boolean"
        @block += "#{check_box :item, field[0]} Checked if active"
      when "file"
        @block += file_field :item, field[0], :style => "border: 0px;"
      when "tags"
        @block += text_field :item, field[0], :value => @item.tags.join(", "), :class => "big"
      when "selector"
        @values = eval field[2]
        @block += select :item, field[0], @values.collect { |p| [ "#{p[0]} (#{p[1]})", p[1] ] }
      when "collection"
        @collection = eval field[0].singularize.capitalize
        @block += collection_select :item, "#{field[0]}_id", @collection.find(:all), :id, :name, :include_blank => true
      when "multiple"
        multiple = eval field[0].singularize.capitalize
        rel_model = "#{field[0].singularize}" + "_id"
        current_model = eval params[:model].singularize.capitalize
        @selected = current_model.find(params[:id]).send(field[0]).collect { |t| t.send(rel_model).to_i } if params[:id]
        @block += "<select name=\"item[tag_ids][]\" multiple=\"multiple\">"
        @block += options_from_collection_for_select(multiple.find(:all), :id, :name, @selected)
        @block += "</select>"
      else
        @block += "Unexisting"
      end
      @block += "</p>"
    end
    return @block
  end

  def typus_form_externals
    @block = ""
    @form_fields_externals.each do |field|
      model_to_relate = eval field[0].singularize.capitalize
      @block += "<h2 style=\"margin: 20px 0px 0px 0px;\">#{field[0].capitalize}</h2>"
      @block += form_tag :action => "relate", :related => "#{field[0]}"
      @block += "<p>"
      @block += select "model_id_to_relate", :related_id, (model_to_relate.find(:all) - @item.send(field[0])).map { |f| [f.name, f.id] }
      @block += "&nbsp; #{submit_tag "Add #{field[0].singularize}"}</p>"
      @block += "</form>"
      current_model = eval params[:model].singularize.capitalize
      items = current_model.find(params[:id]).send(field[0])
      @block += "<ul>"
      items.each { |item| @block += "<li>#{item.name} <small>#{link_to "Remove", :action => "unrelate", :unrelated => field[0], :unrelated_id => item.id, :id => params[:id]}</small></li>" }
      @block += "</ul>"
    end
    return @block
  end

end