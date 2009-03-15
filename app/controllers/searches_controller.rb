class SearchesController < ApplicationController

  MAX_SELECT_PEOPLE = 5
  MAX_SELECT_FAMILIES = 5

  def show
    # A search should be referencable by URI, thus "show" makes sense;
    # though "create" makes more sense from a resource standpoint.
    # We'll do both. :-)
    if params_without_action.any?
      create
    else
      redirect_to new_search_path
    end
  end
  
  def new
  end
  
  def create
    params.reject_blanks!
    @search = Search.new_from_params(params)
    if @search.family_name.blank?
      @people = @search.query(params[:page])
    else
      @families = @search.query(params[:page], 'family')
    end
    @count = @search.count
    @show_birthdays = params[:birthday_month] or params[:birthday_day]
    @business_categories = Person.business_categories if @search.show_businesses
    respond_to do |wants|
      wants.html do
        if @people.length == 1 and (params[:name] or params[:quick_name])
          redirect_to person_path(:id => @people.first)
        else
          render :action => 'new'
        end
      end
      wants.js do
        if params[:auto_complete]
          @people = @people[0..MAX_SELECT_PEOPLE]
          render :partial => 'auto_complete'
        else
          render :update do |page|
            if params[:select_person]
              @people = @people[0..MAX_SELECT_PEOPLE]
              page.replace_html 'results', :partial => 'select_person'
              page.show 'add_member'
            elsif params[:select_family]
              @families = @families[0..MAX_SELECT_FAMILIES]
              page.replace_html 'results', :partial => 'select_family'
              if !@families.empty?
                page.show 'select_family_form'
                page.hide 'no_families_found'
              else
                page.hide 'select_family_form'
                page.show 'no_families_found'
              end
            else
              if @people
                page.replace_html 'results', :partial => 'results'
              elsif @families
                page.replace_html 'results', :partial => 'families_results'
              end
            end
          end
        end
      end
    end
  end
  
  def opensearch
    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

end
