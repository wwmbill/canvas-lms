#
# Copyright (C) 2016 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module Lti
  describe MembershipServiceController do
    context 'course with single enrollment' do
      before(:each) do
        course_with_teacher
      end

      describe "#index" do
        context 'without access token' do
          it 'requires a user' do
            get 'index', course_id: @course.id
            assert_unauthorized
          end
        end

        context 'with access token' do
          before(:each) do
            pseudonym(@teacher)
            @teacher.save!
            token = @teacher.access_tokens.create!(purpose: 'test').full_token
            @request.headers['Authorization'] = "Bearer #{token}"
          end

          it 'outputs the expected data in the expected format at the top level' do
            get 'index', course_id: @course.id
            hash = json_parse.with_indifferent_access
            expect(hash.keys.size).to eq(6)

            expect(hash.fetch(:@id)).to be_nil
            expect(hash.fetch(:@type)).to eq 'Page'
            expect(hash.fetch(:@context)).to eq 'http://purl.imsglobal.org/ctx/lis/v2/MembershipContainer'
            expect(hash.fetch(:differences)).to be_nil
            expect(hash.fetch(:nextPage)).to be_nil
            expect(hash.fetch(:pageOf)).not_to be_nil
          end

          it 'outputs the expected data in the expected format at the container level' do
            get 'index', course_id: @course.id
            hash = json_parse.with_indifferent_access
            container = hash[:pageOf]

            expect(container.size).to eq 5
            expect(container.fetch(:@id)).to be_nil
            expect(container.fetch(:@type)).to eq 'LISMembershipContainer'
            expect(container.fetch(:@context)).to eq 'http://purl.imsglobal.org/ctx/lis/v2/MembershipContainer'
            expect(container.fetch(:membershipPredicate)).to eq 'http://www.w3.org/ns/org#membership'
            expect(container.fetch(:membershipSubject)).not_to be_nil
          end

          it 'outputs the expected data in the expected format at the context level' do
            get 'index', course_id: @course.id
            hash = json_parse.with_indifferent_access
            @course.reload
            context = hash[:pageOf][:membershipSubject]

            expect(context.size).to eq 5
            expect(context.fetch(:@id)).to be_nil
            expect(context.fetch(:@type)).to eq 'Context'
            expect(context.fetch(:name)).to eq @course.name
            expect(context.fetch(:contextId)).to eq @course.lti_context_id
            expect(context.fetch(:membership)).not_to be_nil
          end

          it 'outputs the expected data in the expected format at the membership level' do
            get 'index', course_id: @course.id
            hash = json_parse.with_indifferent_access
            @teacher.reload
            memberships = hash[:pageOf][:membershipSubject][:membership]

            expect(memberships.size).to eq 1

            membership = memberships[0]

            expect(membership.size).to eq 4
            expect(membership.fetch(:@id)).to be_nil
            expect(membership.fetch(:status)).to eq IMS::LIS::Statuses::SimpleNames::Active
            expect(membership.fetch(:role)).to match_array([IMS::LIS::Roles::Context::URNs::Instructor])

            member = membership.fetch(:member)
            expect(member.fetch(:@id)).to be_nil
            expect(member.fetch(:name)).to eq @teacher.name
            expect(member.fetch(:img)).to eq @teacher.avatar_image_url
            expect(member.fetch(:email)).to eq @teacher.email
            expect(member.fetch(:familyName)).to eq @teacher.last_name
            expect(member.fetch(:givenName)).to eq @teacher.first_name
            expect(member.fetch(:resultSourcedId)).to be_nil
            expect(member.fetch(:sourcedId)).to be_nil
            expect(member.fetch(:userId)).to eq(@teacher.lti_context_id)
          end
        end
      end
    end

    context 'course with multiple enrollments' do
      before(:each) do
        course_with_teacher
        @course.enroll_user(@teacher, 'TeacherEnrollment', enrollment_state: 'active')
        @ta = user_model
        @course.enroll_user(@ta, 'TaEnrollment', enrollment_state: 'active')
        @student = user_model
        @course.enroll_user(@student, 'StudentEnrollment', enrollment_state: 'active')

        pseudonym(@teacher)
        @teacher.save!
        token = @teacher.access_tokens.create!(purpose: 'test').full_token
        @request.headers['Authorization'] = "Bearer #{token}"
      end

      describe '#as_json' do
        it 'provides the right next_page url when no page/per_page/role params are given' do
          Api.stubs(:per_page).returns(1)
          get 'index', course_id: @course.id
          hash = json_parse.with_indifferent_access

          uri = URI(hash.fetch(:nextPage))
          expect(uri.scheme).to eq 'http'
          expect(uri.host).to eq 'test.host'
          expect(uri.path).to eq "/api/lti/courses/#{@course.id}/membership_service"
          expect(uri.query).to eq 'page=2&per_page=1'
        end

        it 'provides the right next_page url when page/per_page/role params are given' do
          Api.stubs(:per_page).returns(1)
          get 'index', course_id: @course.id, page: 2, per_page: 1, role: 'Instructor'
          hash = json_parse.with_indifferent_access

          uri = URI(hash.fetch(:nextPage))
          expect(uri.scheme).to eq 'http'
          expect(uri.host).to eq 'test.host'
          expect(uri.path).to eq "/api/lti/courses/#{@course.id}/membership_service"
          expect(uri.query).to eq 'page=3&per_page=1&role=Instructor'
        end

        it 'returns nil for the next page url when the last page in the collection was requested' do
          Api.stubs(:per_page).returns(1)
          get 'index', course_id: @course.id, page: 3, per_page: 1, role: 'Instructor'
          hash = json_parse.with_indifferent_access

          expect(hash.fetch(:nextPage)).to be_nil
        end
      end
    end
  end
end
