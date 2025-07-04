class WorkController < ApplicationController
  def index
    @work = Work.all
  end

  def show
    @work_item = Work.find(params[:id])
  end

  def new
    @work_item = Work.new
  end

  def create
    @work_item = Work.new(work_params)
    if @work_item.save
      redirect_to @work_item
    else
      render :new
    end
  end

  def edit
    @work_item = Work.find(params[:id])
  end

  def update
    @work_item = Work.find(params[:id])
    if @work_item.update(work_params)
      redirect_to @work_item
    else
      render :edit
    end
  end

  def destroy
    @work_item = Work.find(params[:id])
    @work_item.destroy
    redirect_to work_index_path
  end

  private

  def work_params
    params.require(:work).permit(:title, :description, :status)
  end
end
