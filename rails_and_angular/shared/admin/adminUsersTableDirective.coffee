module = require('shared/adminModule')
templateUrl = require('./adminUsersTableTemplate.html')

class AdminUsersTableController
	constructor: (@_$modal, @_$rootScope, @_$scope, @_$state, @_authService, @_permissionsService, @_UsersResource) ->
		@_$scope.$emit('adminUsers:tableRendered')

	getCredentialsFor: (user) ->
		@_UsersResource.credentials({id: user.id}).$promise

	signInAs: (user) ->
		@getCredentialsFor(user).then((credentials) =>
			@_authService.impersonateUser(credentials)
			@_permissionsService.getDefaultTeamId(credentials.user.email).then((teamId) =>
				@_$state.go('content.index', {teamId: teamId})
				@_$scope.$emit('adminUsers:closeModal')
			)
		)

	enable: (user) ->
		@_UsersResource.enable({id: user.id}).$promise.then(@onUserModified)

	disable: (user) ->
		@_UsersResource.disable({id: user.id}).$promise.then(@onUserModified)

	onUserModified: =>
		@_$scope.$emit('adminUsers:userModified')

	showQuotaManagerFor: (user) =>
		newScope = @_$rootScope.$new()
		newScope.user = user
		newScope.onTrialUpdated = @onUserModified
		@_$modal.open({
			scope: newScope
			template: '<wm-admin-user-quota on-trial-updated="onTrialUpdated()" $close="$close" user="user"></wm-admin-user-quota>'
			windowClass: 'admin-user-quotas-modal'
		})

	showContentFor: (user) =>
		newScope = @_$rootScope.$new()
		newScope.user = user
		@_$modal.open({
			scope: newScope
			template: '<wm-admin-content $close="$close" owner="user"></wm-admin-content>'
			windowClass: 'admin-content-manager-modal'
		})

AdminUsersTableController.$inject = ['$modal', '$rootScope', '$scope', '$state', 'authService', 'permissionsService', 'UsersResource']


module.directive('wmAdminUsersTable', -> {
	restrict: 'A'
	scope: {
		users: '='
	}
	bindToController: true
	controllerAs: 'vm'
	controller: AdminUsersTableController
	templateUrl
})
