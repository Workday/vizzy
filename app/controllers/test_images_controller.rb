include Magick

class TestImagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create], if: :json_request?

  def new
    @test_image = TestImage.new
  end

  def index
    @test_images = TestImage.all
  end

  def show
    @test_image = TestImage.find(params[:id])
    commontator_thread_show(@test_image)
  end

  def create
    creation_params = image_params.dup
    creation_params.delete(:test_image_ancestry)

    @test_image = TestImage.new(creation_params)

    test_image_ancestry = image_params[:test_image_ancestry]

    respond_to do |format|
      fail_validation = lambda do |msg|
        format.html { redirect_to :test_images, notice: msg }
        format.json { render json: { error: msg }, status: :bad_request }
        @test_image.destroy
        return
      end

      if !@test_image.build
        fail_validation.call('Invalid build specified')
      else
        test = Test.create_or_find(@test_image.build.project.id, test_image_ancestry)
        @test_image.test = test
        if @test_image.save
          result = @test_image.validate_md5
          if result == :read_error
            fail_validation.call('Could not calculate image md5')
          elsif result == :not_in_build
            fail_validation.call('Matching MD5 not found provided in build')
          elsif result == :mismatched
            fail_validation.call('MD5 does not match MD5 provided to build')
          else
            @test_image.build.remove_md5_for_image(@test_image)
            format.html { redirect_to @test_image, notice: 'Image successfully created' }
            format.json { render :show, status: :created, location: @test_image }
          end
        else
          # Error could not save image
          format.html { render :new }
          format.json { render json: @test_image.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    @test_image = TestImage.find(params[:id])

    old_image_diffs = Diff.where(old_image_id: @test_image.id)
    old_image_diffs.each { |diff| diff.destroy }

    new_image_diffs = Diff.where(new_image_id: @test_image.id)
    new_image_diffs.each { |diff| diff.destroy }


    @test_image.destroy!

    redirect_to test_images_path
  end

  private

  # Use strong_parameters for attribute whitelisting
  # Be sure to update your create() and update() controller methods.
  def image_params
    params.permit(:image, :build_id, :test_id, :approved, :test_image_ancestry)
  end
end
