require 'test_helper'

class HasPaperTrailModelTest < ActiveSupport::TestCase

  context 'A record with defined "only" and "ignore" attributes' do
    setup { @article = Article.create }

    context 'which updates an ignored column' do
      setup { @article.update_attributes :title => 'My first title' }
      should_not_change('the number of versions') { PaperTrail::Version.count }
    end

    context 'which updates an ignored column and a selected column' do
      setup { @article.update_attributes :title => 'My first title', :content => 'Some text here.' }
      should_change('the number of versions', :by => 1) { PaperTrail::Version.count }

      should 'have stored only non-ignored attributes' do
        assert_equal ({'content' => [nil, 'Some text here.']}), @article.versions.last.changeset
      end
    end

    context 'which updates a selected column' do
      setup { @article.update_attributes :content => 'Some text here.' }
      should_change('the number of versions', :by => 1) { PaperTrail::Version.count }
    end

    context 'which updates a non-ignored and non-selected column' do
      setup { @article.update_attributes :abstract => 'Other abstract'}
      should_not_change('the number of versions') { PaperTrail::Version.count }
    end

    context 'which updates a skipped column' do
      setup { @article.update_attributes :file_upload => 'Your data goes here' }
      should_not_change('the number of versions') { PaperTrail::Version.count }
    end

    context 'which updates a skipped column and a selected column' do
      setup { @article.update_attributes :file_upload => 'Your data goes here', :content => 'Some text here.' }
      should_change('the number of versions', :by => 1) { PaperTrail::Version.count }

      should 'have stored only non-skipped attributes' do
        assert_equal ({'content' => [nil, 'Some text here.']}), @article.versions.last.changeset
      end

      context 'and when updated again' do
        setup do
          @article.update_attributes :file_upload => 'More data goes here', :content => 'More text here.'
          @old_article = @article.versions.last
        end

        should 'have removed the skipped attributes when saving the previous version' do
          assert_equal nil, YAML::load(@old_article.object)['file_upload']
        end

        should 'have kept the non-skipped attributes in the previous version' do
          assert_equal 'Some text here.', YAML::load(@old_article.object)['content']
        end
      end
    end
  end

  context 'A record with defined "ignore" attribute' do
    setup { @legacy_widget = LegacyWidget.create }

    context 'which updates an ignored column' do
      setup { @legacy_widget.update_attributes :version => 1 }
      should_not_change('the number of versions') { PaperTrail::Version.count }
    end
  end

  context 'A record with defined "if" and "unless" attributes' do
    setup { @translation = Translation.new :headline => 'Headline' }

    context 'for non-US translations' do
      setup { @translation.save }
      should_not_change('the number of versions') { PaperTrail::Version.count }

      context 'after update' do
        setup { @translation.update_attributes :content => 'Content' }
        should_not_change('the number of versions') { PaperTrail::Version.count }
      end
    end

    context 'for US translations' do
      setup { @translation.language_code = "US" }

      context 'that are drafts' do
        setup do
          @translation.type = 'DRAFT'
          @translation.save
        end

        should_not_change('the number of versions') { PaperTrail::Version.count }

        context 'after update' do
          setup { @translation.update_attributes :content => 'Content' }
          should_not_change('the number of versions') { PaperTrail::Version.count }
        end
      end

      context 'that are not drafts' do
        setup { @translation.save }

        should_change('the number of versions', :by => 1) { PaperTrail::Version.count }

        context 'after update' do
          setup { @translation.update_attributes :content => 'Content' }
          should_change('the number of versions', :by => 1) { PaperTrail::Version.count }
        end
      end
    end
  end

  context 'A new record' do
    setup { @widget = Widget.new }

    should 'not have any previous versions' do
      assert_equal [], @widget.versions
    end

    should 'be live' do
      assert @widget.live?
    end


    context 'which is then created' do
      setup { @widget.update_attributes :name => 'Henry' }

      should 'have one previous version' do
        assert_equal 1, @widget.versions.length
      end

      should 'be nil in its previous version' do
        assert_nil @widget.versions.first.object
        assert_nil @widget.versions.first.reify
      end

      should 'record the correct event' do
        assert_match /create/i, @widget.versions.first.event
      end

      should 'be live' do
        assert @widget.live?
      end

      should 'not have changes' do
        assert_equal Hash.new, @widget.versions.last.changeset
      end

      context 'and then updated without any changes' do
        setup { @widget.save }

        should 'not have a new version' do
          assert_equal 1, @widget.versions.length
        end
      end


      context 'and then updated with changes' do
        setup { @widget.update_attributes :name => 'Harry' }

        should 'have two previous versions' do
          assert_equal 2, @widget.versions.length
        end

        should 'be available in its previous version' do
          assert_equal 'Harry', @widget.name
          assert_not_nil @widget.versions.last.object
          widget = @widget.versions.last.reify
          assert_equal 'Henry', widget.name
          assert_equal 'Harry', @widget.name
        end

        should 'have the same ID in its previous version' do
          assert_equal @widget.id, @widget.versions.last.reify.id
        end

        should 'record the correct event' do
          assert_match /update/i, @widget.versions.last.event
        end

        should 'have versions that are not live' do
          assert @widget.versions.map(&:reify).compact.all? { |w| !w.live? }
        end

        should 'have stored changes' do
          assert_equal ({'name' => ['Henry', 'Harry']}), YAML::load(@widget.versions.last.object_changes)
          assert_equal ({'name' => ['Henry', 'Harry']}), @widget.versions.last.changeset
        end

        should 'return changes with indifferent access' do
          assert_equal ['Henry', 'Harry'], @widget.versions.last.changeset[:name]
          assert_equal ['Henry', 'Harry'], @widget.versions.last.changeset['name']
        end

        if defined?(ActiveRecord::IdentityMap) && ActiveRecord::IdentityMap.respond_to?(:without)
          should 'not clobber the IdentityMap when reifying' do
            module ActiveRecord::IdentityMap
              class << self
                alias :__without :without
                def without(&block)
                  @unclobbered = true
                  __without(&block)
                end
              end
            end

            @widget.versions.last.reify
            assert ActiveRecord::IdentityMap.instance_variable_get("@unclobbered")
          end
        end

        context 'and has one associated object' do
          setup do
            @wotsit = @widget.create_wotsit :name => 'John'
          end

          should 'not copy the has_one association by default when reifying' do
            reified_widget = @widget.versions.last.reify
            assert_equal @wotsit, reified_widget.wotsit  # association hasn't been affected by reifying
            assert_equal @wotsit, @widget.wotsit  # confirm that the association is correct
          end

          should 'copy the has_one association when reifying with :has_one => true' do
            reified_widget = @widget.versions.last.reify(:has_one => true)
            assert_nil reified_widget.wotsit  # wotsit wasn't there at the last version
            assert_equal @wotsit, @widget.wotsit  # wotsit came into being on the live object
          end
        end


        context 'and has many associated objects' do
          setup do
            @f0 = @widget.fluxors.create :name => 'f-zero'
            @f1 = @widget.fluxors.create :name => 'f-one'
            @reified_widget = @widget.versions.last.reify
          end

          should 'copy the has_many associations when reifying' do
            assert_equal @widget.fluxors.length, @reified_widget.fluxors.length
            assert_same_elements @widget.fluxors, @reified_widget.fluxors

            assert_equal @widget.versions.length, @reified_widget.versions.length
            assert_same_elements @widget.versions, @reified_widget.versions
          end
        end


        context 'and then destroyed' do
          setup do
            @fluxor = @widget.fluxors.create :name => 'flux'
            @widget.destroy
            @reified_widget = PaperTrail::Version.last.reify
          end

          should 'record the correct event' do
            assert_match /destroy/i, PaperTrail::Version.last.event
          end

          should 'have three previous versions' do
            assert_equal 3, PaperTrail::Version.with_item_keys('Widget', @widget.id).length
          end

          should 'be available in its previous version' do
            assert_equal @widget.id, @reified_widget.id
            assert_equal @widget.attributes, @reified_widget.attributes
          end

          should 'be re-creatable from its previous version' do
            assert @reified_widget.save
          end

          should 'restore its associations on its previous version' do
            @reified_widget.save
            assert_equal 1, @reified_widget.fluxors.length
          end

          should 'not have changes' do
            assert_equal Hash.new, @widget.versions.last.changeset
          end
        end
      end
    end
  end


  # Test the serialisation and deserialisation.
  # TODO: binary
  context "A record's papertrail" do
    setup do
      @date_time = DateTime.now.utc
      @time = Time.now
      @date = Date.new 2009, 5, 29
      @widget = Widget.create :name        => 'Warble',
                              :a_text      => 'The quick brown fox',
                              :an_integer  => 42,
                              :a_float     => 153.01,
                              :a_decimal   => 2.71828,
                              :a_datetime  => @date_time,
                              :a_time      => @time,
                              :a_date      => @date,
                              :a_boolean   => true

      @widget.update_attributes :name      => nil,
                              :a_text      => nil,
                              :an_integer  => nil,
                              :a_float     => nil,
                              :a_decimal   => nil,
                              :a_datetime  => nil,
                              :a_time      => nil,
                              :a_date      => nil,
                              :a_boolean   => false
      @previous = @widget.versions.last.reify
    end

    should 'handle strings' do
      assert_equal 'Warble', @previous.name
    end

    should 'handle text' do
      assert_equal 'The quick brown fox', @previous.a_text
    end

    should 'handle integers' do
      assert_equal 42, @previous.an_integer
    end

    should 'handle floats' do
      assert_in_delta 153.01, @previous.a_float, 0.001
    end

    should 'handle decimals' do
      assert_in_delta 2.71828, @previous.a_decimal, 0.00001
    end

    should 'handle datetimes' do
      assert_equal @date_time.to_time.utc.to_i, @previous.a_datetime.to_time.utc.to_i
    end

    should 'handle times' do
      assert_equal @time.utc.to_i, @previous.a_time.utc.to_i
    end

    should 'handle dates' do
      assert_equal @date, @previous.a_date
    end

    should 'handle booleans' do
      assert @previous.a_boolean
    end


    context "after a column is removed from the record's schema" do
      setup do
        change_schema
        Widget.reset_column_information
        assert_raise(NoMethodError) { Widget.new.sacrificial_column }
        @last = @widget.versions.last
      end

      should 'reify previous version' do
        assert_kind_of Widget, @last.reify
      end

      should 'restore all forward-compatible attributes' do
        assert_equal    'Warble',                    @last.reify.name
        assert_equal    'The quick brown fox',       @last.reify.a_text
        assert_equal    42,                          @last.reify.an_integer
        assert_in_delta 153.01,                      @last.reify.a_float,   0.001
        assert_in_delta 2.71828,                     @last.reify.a_decimal, 0.00001
        assert_equal    @date_time.to_time.utc.to_i, @last.reify.a_datetime.to_time.utc.to_i
        assert_equal    @time.utc.to_i,              @last.reify.a_time.utc.to_i
        assert_equal    @date,                       @last.reify.a_date
        assert          @last.reify.a_boolean
      end
    end
  end


  context 'A record' do
    setup { @widget = Widget.create :name => 'Zaphod' }

    context 'with PaperTrail globally disabled' do
      setup do
        PaperTrail.enabled = false
        @count = @widget.versions.length
      end

      teardown { PaperTrail.enabled = true }

      context 'when updated' do
        setup { @widget.update_attributes :name => 'Beeblebrox' }

        should 'not add to its trail' do
          assert_equal @count, @widget.versions.length
        end
      end
    end

    context 'with its paper trail turned off' do
      setup do
        Widget.paper_trail_off
        @count = @widget.versions.length
      end

      teardown { Widget.paper_trail_on }

      context 'when updated' do
        setup { @widget.update_attributes :name => 'Beeblebrox' }

        should 'not add to its trail' do
          assert_equal @count, @widget.versions.length
        end
      end

      context 'when destroyed "without versioning"' do
        should 'leave paper trail off after call' do
          @widget.without_versioning :destroy
          assert !Widget.paper_trail_enabled_for_model
        end
      end

      context 'and then its paper trail turned on' do
        setup { Widget.paper_trail_on }

        context 'when updated' do
          setup { @widget.update_attributes :name => 'Ford' }

          should 'add to its trail' do
            assert_equal @count + 1, @widget.versions.length
          end
        end

        context 'when updated "without versioning"' do
          setup do
            @widget.without_versioning do
              @widget.update_attributes :name => 'Ford'
            end
          end

          should 'not create new version' do
            assert_equal 1, @widget.versions.length
          end

          should 'enable paper trail after call' do
            assert Widget.paper_trail_enabled_for_model
          end
        end
      end
    end
  end


  context 'A papertrail with somebody making changes' do
    setup do
      @widget = Widget.new :name => 'Fidget'
    end

    context 'when a record is created' do
      setup do
        PaperTrail.whodunnit = 'Alice'
        @widget.save
        @version = @widget.versions.last  # only 1 version
      end

      should 'track who made the change' do
        assert_equal 'Alice', @version.whodunnit
        assert_nil   @version.originator
        assert_equal 'Alice', @version.terminator
        assert_equal 'Alice', @widget.originator
      end

      context 'when a record is updated' do
        setup do
          PaperTrail.whodunnit = 'Bob'
          @widget.update_attributes :name => 'Rivet'
          @version = @widget.versions.last
        end

        should 'track who made the change' do
          assert_equal 'Bob',   @version.whodunnit
          assert_equal 'Alice', @version.originator
          assert_equal 'Bob',   @version.terminator
          assert_equal 'Bob',   @widget.originator
        end

        context 'when a record is destroyed' do
          setup do
            PaperTrail.whodunnit = 'Charlie'
            @widget.destroy
            @version = PaperTrail::Version.last
          end

          should 'track who made the change' do
            assert_equal 'Charlie', @version.whodunnit
            assert_equal 'Bob',     @version.originator
            assert_equal 'Charlie', @version.terminator
            assert_equal 'Charlie', @widget.originator
          end
        end
      end
    end
  end


  context 'A subclass' do
    setup do
      @foo = FooWidget.create
      @foo.update_attributes :name => 'Fooey'
    end

    should 'reify with the correct type' do
      thing = PaperTrail::Version.last.reify
      assert_kind_of FooWidget, thing
      assert_equal @foo.versions.first, PaperTrail::Version.last.previous
      assert_nil PaperTrail::Version.last.next
    end

    context 'when destroyed' do
      setup { @foo.destroy }

      should 'reify with the correct type' do
        thing = PaperTrail::Version.last.reify
        assert_kind_of FooWidget, thing
        assert_equal @foo.versions[1], PaperTrail::Version.last.previous
        assert_nil PaperTrail::Version.last.next
      end
    end
  end


  context 'An item with versions' do
    setup do
      @widget = Widget.create :name => 'Widget'
      @widget.update_attributes :name => 'Fidget'
      @widget.update_attributes :name => 'Digit'
    end

    context 'which were created over time' do
      setup do
        @created       = 2.days.ago
        @first_update  = 1.day.ago
        @second_update = 1.hour.ago
        @widget.versions[0].update_attributes :created_at => @created
        @widget.versions[1].update_attributes :created_at => @first_update
        @widget.versions[2].update_attributes :created_at => @second_update
        @widget.update_attribute :updated_at, @second_update
      end

      should 'return nil for version_at before it was created' do
        assert_nil @widget.version_at(@created - 1)
      end

      should 'return how it looked when created for version_at its creation' do
        assert_equal 'Widget', @widget.version_at(@created).name
      end

      should "return how it looked when created for version_at just before its first update" do
        assert_equal 'Widget', @widget.version_at(@first_update - 1).name
      end

      should "return how it looked when first updated for version_at its first update" do
        assert_equal 'Fidget', @widget.version_at(@first_update).name
      end

      should 'return how it looked when first updated for version_at just before its second update' do
        assert_equal 'Fidget', @widget.version_at(@second_update - 1).name
      end

      should 'return how it looked when subsequently updated for version_at its second update' do
        assert_equal 'Digit', @widget.version_at(@second_update).name
      end

      should 'return the current object for version_at after latest update' do
        assert_equal 'Digit', @widget.version_at(1.day.from_now).name
      end
    end

    context '.versions_between' do
      setup do
        @created       = 30.days.ago
        @first_update  = 15.days.ago
        @second_update = 1.day.ago
        @widget.versions[0].update_attributes :created_at => @created
        @widget.versions[1].update_attributes :created_at => @first_update
        @widget.versions[2].update_attributes :created_at => @second_update
        @widget.update_attribute :updated_at, @second_update
      end

      should 'return versions in the time period' do
        assert_equal ['Fidget'], @widget.versions_between(20.days.ago, 10.days.ago).map(&:name)
        assert_equal ['Widget', 'Fidget'], @widget.versions_between(45.days.ago, 10.days.ago).map(&:name)
        assert_equal ['Fidget', 'Digit'], @widget.versions_between(16.days.ago, 1.minute.ago).map(&:name)
        assert_equal [], @widget.versions_between(60.days.ago, 45.days.ago).map(&:name)
      end
    end

    context 'on the first version' do
      setup { @version = @widget.versions.first }

      should 'have a nil previous version' do
        assert_nil @version.previous
      end

      should 'return the next version' do
        assert_equal @widget.versions[1], @version.next
      end

      should 'return the correct index' do
        assert_equal 0, @version.index
      end
    end

    context 'on the last version' do
      setup { @version = @widget.versions.last }

      should 'return the previous version' do
        assert_equal @widget.versions[@widget.versions.length - 2], @version.previous
      end

      should 'have a nil next version' do
        assert_nil @version.next
      end

      should 'return the correct index' do
        assert_equal @widget.versions.length - 1, @version.index
      end
    end
  end


  context 'An item' do
    setup { @article = Article.new }

    context 'which is created' do
      setup { @article.save }

      should 'store fixed meta data' do
        assert_equal 42, @article.versions.last.answer
      end

      should 'store dynamic meta data which is independent of the item' do
        assert_equal '31 + 11 = 42', @article.versions.last.question
      end

      should 'store dynamic meta data which depends on the item' do
        assert_equal @article.id, @article.versions.last.article_id
      end

      should 'store dynamic meta data based on a method of the item' do
        assert_equal @article.action_data_provider_method, @article.versions.last.action
      end


      context 'and updated' do
        setup { @article.update_attributes! :content => 'Better text.' }

        should 'store fixed meta data' do
          assert_equal 42, @article.versions.last.answer
        end

        should 'store dynamic meta data which is independent of the item' do
          assert_equal '31 + 11 = 42', @article.versions.last.question
        end

        should 'store dynamic meta data which depends on the item' do
          assert_equal @article.id, @article.versions.last.article_id
        end
      end


      context 'and destroyed' do
        setup { @article.destroy }

        should 'store fixed meta data' do
          assert_equal 42, @article.versions.last.answer
        end

        should 'store dynamic meta data which is independent of the item' do
          assert_equal '31 + 11 = 42', @article.versions.last.question
        end

        should 'store dynamic meta data which depends on the item' do
          assert_equal @article.id, @article.versions.last.article_id
        end

      end
    end
  end

  context 'A reified item' do
    setup do
      widget = Widget.create :name => 'Bob'
      %w( Tom Dick Jane ).each { |name| widget.update_attributes :name => name }
      @version = widget.versions.last
      @widget = @version.reify
    end

    should 'know which version it came from' do
      assert_equal @version, @widget.version
    end

    should 'return its previous self' do
      assert_equal @widget.versions[-2].reify, @widget.previous_version
    end

  end


  context 'A non-reified item' do
    setup { @widget = Widget.new }

    should 'not have a previous version' do
      assert_nil @widget.previous_version
    end

    should 'not have a next version' do
      assert_nil @widget.next_version
    end

    context 'with versions' do
      setup do
        @widget.save
        %w( Tom Dick Jane ).each { |name| @widget.update_attributes :name => name }
      end

      should 'have a previous version' do
        assert_equal @widget.versions.last.reify, @widget.previous_version
      end

      should 'have a next version' do
        assert_nil @widget.next_version
      end
    end
  end

  context 'A reified item' do
    setup do
      widget = Widget.create :name => 'Bob'
      %w( Tom Dick Jane ).each { |name| widget.update_attributes :name => name }
      @versions      = widget.versions
      @second_widget = @versions[1].reify  # first widget is null
      @last_widget   = @versions.last.reify
    end

    should 'have a previous version' do
      assert_nil @second_widget.previous_version
      assert_equal @versions[-2].reify, @last_widget.previous_version
    end

    should 'have a next version' do
      assert_equal @versions[2].reify, @second_widget.next_version
      assert_nil @last_widget.next_version
    end
  end

  context ":has_many :through" do
    setup do
      @book = Book.create :title => 'War and Peace'
      @dostoyevsky  = Person.create :name => 'Dostoyevsky'
      @solzhenitsyn = Person.create :name => 'Solzhenitsyn'
    end

    should 'store version on source <<' do
      count = PaperTrail::Version.count
      @book.authors << @dostoyevsky
      assert_equal 1, PaperTrail::Version.count - count
      assert_equal PaperTrail::Version.last, @book.authorships.first.versions.first
    end

    should 'store version on source create' do
      count = PaperTrail::Version.count
      @book.authors.create :name => 'Tolstoy'
      assert_equal 2, PaperTrail::Version.count - count
      assert_same_elements [Person.last, Authorship.last], [PaperTrail::Version.all[-2].item, PaperTrail::Version.last.item]
    end

    should 'store version on join destroy' do
      @book.authors << @dostoyevsky
      count = PaperTrail::Version.count
      @book.authorships(true).last.destroy
      assert_equal 1, PaperTrail::Version.count - count
      assert_equal @book, PaperTrail::Version.last.reify.book
      assert_equal @dostoyevsky, PaperTrail::Version.last.reify.person
    end

    should 'store version on join clear' do
      @book.authors << @dostoyevsky
      count = PaperTrail::Version.count
      @book.authorships(true).clear
      assert_equal 1, PaperTrail::Version.count - count
      assert_equal @book, PaperTrail::Version.last.reify.book
      assert_equal @dostoyevsky, PaperTrail::Version.last.reify.person
    end
  end


  context 'A model with a has_one association' do
    setup { @widget = Widget.create :name => 'widget_0' }

    context 'before the associated was created' do
      setup do
        @widget.update_attributes :name => 'widget_1'
        @wotsit = @widget.create_wotsit :name => 'wotsit_0'
      end

      context 'when reified' do
        setup { @widget_0 = @widget.versions.last.reify(:has_one => 1) }

        should 'see the associated as it was at the time' do
          assert_nil @widget_0.wotsit
        end
      end
    end

    context 'where the associated is created between model versions' do
      setup do
        @wotsit = @widget.create_wotsit :name => 'wotsit_0'
        make_last_version_earlier @wotsit

        @widget.update_attributes :name => 'widget_1'
      end

      context 'when reified' do
        setup { @widget_0 = @widget.versions.last.reify(:has_one => 1) }

        should 'see the associated as it was at the time' do
          assert_equal 'wotsit_0', @widget_0.wotsit.name
        end
      end

      context 'and then the associated is updated between model versions' do
        setup do
          @wotsit.update_attributes :name => 'wotsit_1'
          make_last_version_earlier @wotsit
          @wotsit.update_attributes :name => 'wotsit_2'
          make_last_version_earlier @wotsit

          @widget.update_attributes :name => 'widget_2'
          @wotsit.update_attributes :name => 'wotsit_3'
        end

        context 'when reified' do
          setup { @widget_1 = @widget.versions.last.reify(:has_one => 1) }

          should 'see the associated as it was at the time' do
            assert_equal 'wotsit_2', @widget_1.wotsit.name
          end
        end

        context 'when reified opting out of has_one reification' do
          setup { @widget_1 = @widget.versions.last.reify(:has_one => false) }

          should 'see the associated as it is live' do
            assert_equal 'wotsit_3', @widget_1.wotsit.name
          end
        end
      end

      context 'and then the associated is destroyed between model versions' do
        setup do
          @wotsit.destroy
          make_last_version_earlier @wotsit

          @widget.update_attributes :name => 'widget_3'
        end

        context 'when reified' do
          setup { @widget_2 = @widget.versions.last.reify(:has_one => 1) }

          should 'see the associated as it was at the time' do
            assert_nil @widget_2.wotsit
          end
        end
      end
    end
  end

  context 'A new model instance which uses a custom PaperTrail::Version class' do
    setup { @post = Post.new }

    context 'which is then saved' do
      setup { @post.save }
      should_change('the number of post versions') { PostVersion.count }
      should_not_change('the number of versions') { PaperTrail::Version.count }
    end
  end

  context 'An existing model instance which uses a custom PaperTrail::Version class' do
    setup { @post = Post.create }

    context 'on the first version' do
      setup { @version = @post.versions.first }

      should 'have the correct index' do
        assert_equal 0, @version.index
      end
    end

    should 'have versions of the custom class' do
      assert_equal "PostVersion", @post.versions.first.class.name
    end

    context 'which is modified' do
      setup { @post.update_attributes({ :content => "Some new content" }) }
      should_change('the number of post versions') { PostVersion.count }
      should_not_change('the number of versions') { PaperTrail::Version.count }
      should "not have stored changes when object_changes column doesn't exist" do
        assert_nil @post.versions.last.changeset
      end
    end
  end


  context 'An overwritten default accessor' do
    setup do
      @song = Song.create :length => 4
      @song.update_attributes :length => 5
    end

    should 'return "overwritten" value on live instance' do
      assert_equal 5, @song.length
    end
    should 'return "overwritten" value on reified instance' do
      assert_equal 4, @song.versions.last.reify.length
    end
  end


  context 'An unsaved record' do
    setup do
      @widget = Widget.new
      @widget.destroy
    end
    should 'not have a version created on destroy' do
      assert @widget.versions.empty?
    end
  end

  context 'A model with a custom association' do
    setup do
      @doc = Document.create
      @doc.update_attributes :name => 'Doc 1'
    end

    should 'not respond to versions method' do
      assert !@doc.respond_to?(:versions)
    end

    should 'create a new version record' do
      assert_equal 2, @doc.paper_trail_versions.length
    end

    should 'respond to previous_version as normal' do
      @doc.update_attributes :name => 'Doc 2'
      assert_equal 3, @doc.paper_trail_versions.length
      assert_equal 'Doc 1', @doc.previous_version.name
    end
  end

  context 'The `on` option' do
    context 'on create' do
      setup do
        Fluxor.instance_eval <<-END
          has_paper_trail :on => [:create]
        END
        @fluxor = Fluxor.create
        @fluxor.update_attributes :name => 'blah'
        @fluxor.destroy
      end
      should 'only have a version for the create event' do
        assert_equal 1, @fluxor.versions.length
        assert_equal 'create', @fluxor.versions.last.event
      end
    end
    context 'on update' do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
          has_paper_trail :on => [:update]
        END
        @fluxor = Fluxor.create
        @fluxor.update_attributes :name => 'blah'
        @fluxor.destroy
      end
      should 'only have a version for the update event' do
        assert_equal 1, @fluxor.versions.length
        assert_equal 'update', @fluxor.versions.last.event
      end
    end
    context 'on destroy' do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
          has_paper_trail :on => [:destroy]
        END
        @fluxor = Fluxor.create
        @fluxor.update_attributes :name => 'blah'
        @fluxor.destroy
      end
      should 'only have a version for the destroy event' do
        assert_equal 1, @fluxor.versions.length
        assert_equal 'destroy', @fluxor.versions.last.event
      end
    end
  end

  context 'A model with column version and custom version_method' do
    setup do
      @legacy_widget = LegacyWidget.create(:name => "foo", :version => 2)
    end

    should 'set version on create' do
      assert_equal 2, @legacy_widget.version
    end

    should 'allow version updates' do
      @legacy_widget.update_attributes :version => 3
      assert_equal 3, @legacy_widget.version
    end

    should 'create a new version record' do
      assert_equal 1, @legacy_widget.versions.size
    end
  end

  context 'A reified item with a column -version- and custom version_method' do
    setup do
      widget = LegacyWidget.create(:name => "foo", :version => 2)
      %w( bar baz ).each { |name| widget.update_attributes :name => name }
      @version = widget.versions.last
      @widget = @version.reify
    end

    should 'know which version it came from' do
      assert_equal @version, @widget.custom_version
    end

    should 'return its previous self' do
      assert_equal @widget.versions[-2].reify, @widget.previous_version
    end
  end

  private

  # Updates `model`'s last version so it looks like the version was
  # created 2 seconds ago.
  def make_last_version_earlier(model)
    PaperTrail::Version.record_timestamps = false
    model.versions.last.update_attributes :created_at => 2.seconds.ago
    PaperTrail::Version.record_timestamps = true
  end

end
