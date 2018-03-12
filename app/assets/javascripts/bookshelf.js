document.addEventListener('turbolinks:load', function () {

  	var $books = $( '.book-list .book' ), booksCount = $books.length;

    if (booksCount > 0) {
      $overlay = $('<div class="book-underlay is-hidden-mobile is-hidden"></div>').appendTo('body');

      $('.book-list').on('click', '.book:not(.open)', function() {
        $('.book.open').removeClass('open');
        $(this).addClass('open');
        $overlay.removeClass('is-hidden');
				$(this).find('.book-page .book-content').removeClass('book-content-current').eq(0).addClass('book-content-current');
      });

      $('.book + .read-more').on('click', function() {
        $('.book.open').removeClass('open');
        $(this).prev('.book').addClass('open');
        $overlay.removeClass('is-hidden');
				$(this).prev('.book').find('.book-page .book-content').removeClass('book-content-current').eq(0).addClass('book-content-current');
      });

      $(document).on('click', '.book-underlay, .book-page .delete', function() {
        $('.book.open').removeClass('open');
        $overlay.addClass('is-hidden');
      });
    }
		$books.each( function() {
			var $book = $( this ),
				$page = $book.children( '.book-page' ),
				$content = $page.children( '.book-content' ), current = 0;

			if( $content.length > 1 ) {

				var $navPrev = $( '<a class="button book-page-prev"><span class="icon">&lt;</span></a>' ),
					$navNext = $( '<a class="button book-page-next"><span class="icon">&gt;</span></a>' );

				$page.append( $( '<nav></nav>' ).append( $navPrev, $navNext ) );

				$navPrev.on( 'click', function() {
					if( current > 0 ) {
						--current;
						$content.removeClass( 'book-content-current' ).eq( current ).addClass( 'book-content-current' );
					}
					return false;
				} );

				$navNext.on( 'click', function() {
					if( current < $content.length - 1 ) {
						++current;
						$content.removeClass( 'book-content-current' ).eq( current ).addClass( 'book-content-current' );
					}
					return false;
				} );

			}

		} );
});
