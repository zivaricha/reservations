class WelcomeController < ApplicationController
  require 'csv'  
  require "open-uri"
  CSV_URL = "https://gist.githubusercontent.com/yonbergman/7a0b05d6420dada16b92885780567e60/raw/7fc53874485bbee4b29f9ec9639b5b40654ebfa9/data.csv"

  def new
    
    
  end
  
  def create
    url = CSV_URL # default csv url is the one given in the email
    url = params[:url][:csv_file_url] if params[:url].present? && params[:url][:csv_file_url].present?
    @error_message = ""
    begin
      url_data = open(url).read()
      csv = CSV.parse(url_data, :headers=>true, :header_converters=> lambda {|f| f.strip},
                               :converters=> lambda {|f| f ? f.strip : nil})
      first_date_of_input_month = (params["room"]["reservation_month"] + "-01").to_date
    rescue Exception => e
      @error_message = "One of the inputs you have entered is invalid - #{e.message}"
    end
    render 'new' and return if @error_message.present?
    days_of_month = first_date_of_input_month.to_date.end_of_month.day
    revenue_sum = 0
    unreserved_capacity = 0
    csv.each do |row|
      room_capacity = row["Capacity"].to_i
      monthly_price = row["Monthly Price"].to_f
      price_per_day = monthly_price / days_of_month
      start_day = row["Start Day"].to_date
      end_day = row["End Day"].present? ? row["End Day"].to_date : nil
      if end_day.blank?
        if ((start_day.year < first_date_of_input_month.year) || ((start_day.year == first_date_of_input_month.year) && 
          (start_day.month < first_date_of_input_month.month)))
          revenue_sum += monthly_price
        elsif start_day.year == first_date_of_input_month.year && start_day.month == first_date_of_input_month.month
          revenue_sum += price_per_day * (days_of_month - start_day.day + 1)
        else
           unreserved_capacity += room_capacity
        end
      elsif (((start_day.year == first_date_of_input_month.year && start_day.month <= first_date_of_input_month.month) || 
              (start_day.year < first_date_of_input_month.year)) && 
              ((end_day.year == first_date_of_input_month.year && end_day.month >= first_date_of_input_month.month) || 
              (end_day.year > first_date_of_input_month.year)))
             if ((first_date_of_input_month.year > start_day.year && first_date_of_input_month.year < end_day.year) ||
                 (first_date_of_input_month.year == start_day.year && first_date_of_input_month.year < end_day.year && 
                   first_date_of_input_month.month > start_day.month) || 
                   (first_date_of_input_month.year > start_day.year && first_date_of_input_month.year == end_day.year &&
                   first_date_of_input_month.month < end_day.month) ||
                   (first_date_of_input_month.year == start_day.year && first_date_of_input_month.year == end_day.year &&
                   first_date_of_input_month.month > start_day.month && first_date_of_input_month.month < end_day.month))
                 revenue_sum += monthly_price
             elsif (first_date_of_input_month.year == start_day.year && first_date_of_input_month.year < end_day.year &&
                   first_date_of_input_month.month == start_day.month) ||
                   (first_date_of_input_month.year == start_day.year && first_date_of_input_month.year == end_day.year &&
                   first_date_of_input_month.month == start_day.month && first_date_of_input_month.month < end_day.month)
                 revenue_sum += price_per_day * (days_of_month - start_day.day + 1)
             elsif (first_date_of_input_month.year > start_day.year && first_date_of_input_month.year == end_day.year &&
                    first_date_of_input_month.month == end_day.month) ||
                   ( first_date_of_input_month.year == start_day.year && first_date_of_input_month.year == end_day.year &&
                    first_date_of_input_month.month > start_day.month && first_date_of_input_month.month == end_day.month)
                 revenue_sum += price_per_day * end_day.day
             elsif first_date_of_input_month.year == start_day.year && first_date_of_input_month.year == end_day.year &&
                   first_date_of_input_month.month == start_day.month && first_date_of_input_month.month == end_day.month
                 revenue_sum += price_per_day * (end_day.day - start_day.day + 1)
             end
      else # office is not reserved for given month and year
       unreserved_capacity += room_capacity
      end
    end
    @input_month = params["room"]["reservation_month"]
    @revenue_sum = revenue_sum.to_i
    @unreserved_capacity = unreserved_capacity
    render 'new'
  end
end
